#!/bin/bash
source `which my_do_cmd`

# some defaults
designer_container=/home/inb/soporte/lanirem_software/containers/designer2.sif

doPermute=0
doScale=0
scaleFactor=10
doFlips=0
flipX=0
flipY=0
flipZ=0
keep_tmp=0
nthreads=$(( $(getconf _NPROCESSORS_ONLN) -2 ))
list_of_inputs=""

colorinfo="cyan"
colorwarning="orange"
colorerror="red"



function help(){
echo "
`basename $0` <-i dwi.nii.gz> [-i dwi2.nii.gz] <-o outbase>

Take one or more 2D-EPI DWI acquisitions and preprocess them according to:

0. Concatenate the input DWIs if there is more than one input.
1. dwidenoise (mrtrix, Exp2 estimator - Cordero-Grande 2019, or
               optionally, designerv2).
2. eddy (fsl), including eddy_quad for quality check
3. bias-field correction (N4BiasFieldCorrection). Parameters set for rat imaging.


You must invoke at least one input file (-i) and one output file (-o).
The format of the input file must be .nii.gz, and there must be corresponding
bvec and bval files with the same name as the .nii.gz.
Only specify the NAME.nii.gz file, the NAME.bvec and NAME.bval files will be
searched automatically (thus, they must be named accordingly!).

The option exists to use more than one input, for cases where the same specimen was scanned
in different experiments (but the same session). For every -i file, there must
exist the corresponding bvec and bval files.

Only specify the prefix for your output files, as there will be many.
Outputs will be:

  outbase_d.{bvec,bval,nii.gz}   : denoised
  outbase_de.{bvec,bval,nii.gz}  : denoised, eddycorrected
  outbase_deb.{bvec,bval,nii.gz} : denoised, eddycorrected, biasfieldcorrected
  outbase_de.qc/                 : A folder with the eddy quality check
                                   For convenience, many intermediary outputs
                                   are sent to this folder.


Options:

-d            Use designerv2 for denoising.
-c            Full path for designer container.
              Default: $designer_container
-p            Permute axes to 0,2,1,3 (don't do it)
-s <factor>   Scale the image voxel dimensions by some factor (e.g. 2, or 10).
              Useful for eddy, as it is expecting human data, not from rodents.
-m            Perform motion correction (mcflirt) before running eddy.
              This is useful for removing image drift during acquisition.


Flip diffusion gradient vector components:
              You can use none, one or any combination of the following.
              This is useful if your conversion from bruker data messes up the gradients.
-x            Flip x component of diffusion gradient direction
-y            Flip y component of diffusion gradient direction
-z            Flip z component of diffusion gradient direction
-t            Keep temporary directory.

NOTES:

The version of eddy used is explicitly set to eddy_cuda10.2. If not configured
properly, the script will gracefully exit with error.

Requires:
  mrtrix >3.0.2
  fsl >6.0.2

If using Designerv2, you need the singularity container and the singularity module.

Tested on 2D-EPI DWI data from Bruker. Should work on 3D-EPI as well.
Tested on rat data only so far. There are far better tools for human data (dwifslpreproc).
Perhaps not suited for ex vivo data acquired with segmented 3D-EPI, but try for yourself.

LU15 (0N(H4
INB-UNAM
August 2021
lconcha@unam.mx
"
}






if [ $nthreads -lt 1 ]
then
  nthreads=1
fi

while getopts i:o:s:c:dpmxyzt flag
do
    case "${flag}" in
        i) input_file=${OPTARG}
           list_of_inputs="$list_of_inputs $input_file";;
        o) outbase=${OPTARG};;
        d) doDesigner=1;;
        c) designer_container=${OPTARG};;
        p) doPermute=1;;
        s) doScale=1
           scaleFactor=${OPTARG};;
        m) doMotion=1;;
        x) flipX=1
           echo "[INFO]  Will flip X"
           doFlips=1;;
        y) flipY=1
           echo "[INFO]  Will flip Y"
           doFlips=1;;
        z) flipZ=1
           echo "[INFO]  Will flip Z"
           doFlips=1;;
        t) keep_tmp=1
           echo "[INFO] Will keep temporary directory";;
    esac
done



if [ -z "$list_of_inputs" ]
then
    help; exit 2
fi
if [ -z "$outbase" ]
then
    help; exit 2
fi


echo "[INFO] Running on $(hostname)"
echo "[INFO] $(date)"
echo "[INFO] $(lspci | grep VGA)"
echo "[INFO] List of inputs is:"
echo "       $list_of_inputs"
echo "[INFO] outbase is $outbase"
echo "[INFO]" nthreads is $nthreads



date
echo "[INFO] Running on $HOSTNAME"

## check that we can run CUDA
thisoutput=`eddy_cuda10.2 2>&1 | grep "shared libraries"`
if [ ! -z "$thisoutput" ]
then
  echo $thisoutput
  echo "[ERROR] CUDA is not OK."
  echo "[ERROR] Cannot run eddy_cuda on $HOSTNAME, please configure it."
  exit 2
fi 

## check that we can run N4
thisoutput=`N4BiasFieldCorrection --version 2>&1 | grep "ANTs Version"`
if [ -z "$thisoutput" ]
then
  echo $thisoutput
  echo "[ERROR] ANTs is not OK."
  echo "[ERROR] Cannot run N4BiasFieldCorrection on $HOSTNAME, please configure it."
  exit 2
fi 

# Check that we can run designer
if [ $doDesigner -eq 1 ]
then
  echolor $colorinfo "[INFO] Will denoise with designer"
  if [ -z "$(which singularity)" ]
  then
    echo "[ERROR] Cannot find singularity. Perhaps: module load singularity ?"
    exit 2
  fi
  if [ ! -f $designer_container ]
  then
    echo "[ERROR] Cannot find designer container: $designer_container"
    exit 2
  fi
fi



tmpDir=tmp_$$
mkdir $tmpDir



## Concatenate inputs
n=0
for thisdwi in $list_of_inputs
do
  nn=`zeropad $n 3`
  thisbvec=${thisdwi%.nii*}.bvec
  thisbval=${thisdwi%.nii*}.bval
  for f in $thisbvec $thisbval
  do
    if [ ! -f $f ]; then echo "[ERROR] Cannot find $f";exit 2;fi
  done
  my_do_cmd mrconvert -nthreads $nthreads \
    -bvalue_scaling false \
    -fslgrad $thisbvec $thisbval \
    $thisdwi \
    ${tmpDir}/i_dwi_${nn}.mif
  n=$(( $n + 1 ))
done



mifconcatenated=${tmpDir}/dwi_concatenated.mif
if [ $n -gt 1 ]
then
  my_do_cmd mrcat -nthreads $nthreads  -axis 3 \
    ${tmpDir}/i_dwi_*.mif \
    $mifconcatenated
else
  echo "[INFO] Single input, copying directly."
  my_do_cmd cp -v ${tmpDir}/i_dwi_*.mif $mifconcatenated
fi




if [ $doPermute -eq 1 ]
then
   echolor yellow "Will permute dimensions to 0,2,1,3"
   my_do_cmd mrconvert -nthreads $nthreads -axes 0,2,1,3 \
      $mifconcatenated \
      ${tmpDir}/dwi_concatenated_permuted.mif
      mifconcatenated=${tmpDir}/dwi_concatenated_permuted.mif
fi





if [ $doScale -eq 1 ]
then
    echolor yellow "Will scale image voxel ${scaleFactor}X"
    dims=`mrinfo -spacing $mifconcatenated`
    arrdims=($dims)
    x=${arrdims[0]}; xs=$(echo $x*$scaleFactor | bc -l)
    y=${arrdims[1]}; ys=$(echo $y*$scaleFactor | bc -l)
    z=${arrdims[2]}; zs=$(echo $z*$scaleFactor | bc -l)
    my_do_cmd mrconvert -vox "${xs},${ys},${zs}" $mifconcatenated ${mifconcatenated%.mif}_scaled.mif
    mifconcatenated=${mifconcatenated%.mif}_scaled.mif
fi


# convert to nifti
echolor yellow " Converting to NIFTI"
DWIconcatenated=${outbase}_DWI.nii.gz
bvec=${DWIconcatenated%.nii.gz}.bvec
bval=${DWIconcatenated%.nii.gz}.bval
my_do_cmd mrconvert -nthreads $nthreads \
  -bvalue_scaling false \
  -export_grad_fsl $bvec $bval \
  $mifconcatenated \
  $DWIconcatenated


theFlips=""
if [ $doFlips -eq 1 ]
then
  echolor yellow "Will flip gradient vectors"
  if [ $flipX -eq 1 ]; then theFlips="${theFlips} -flip_x";fi
  if [ $flipY -eq 1 ]; then theFlips="${theFlips} -flip_y";fi
  if [ $flipZ -eq 1 ]; then theFlips="${theFlips} -flip_z";fi
  mv -v $bvec ${tmpDir}/notrotated.bvec
  my_do_cmd flip_gradients.sh ${tmpDir}/notrotated.bvec $bvec $theFlips
fi






## Denoising
DWIdenoised=${outbase}_d.nii.gz
echolor $colorinfo "[INFO] Looking for $DWIdenoised"
if [ ! -f $DWIdenoised ]
then
  echolor $colorinfo "[INFO] Denoising..."
  if [ $doDesigner -eq 1 ]
  then
    echolor $colorinfo "[INFO] Denoising with designerv2"
    singularity run --nv \
    -B /misc \
    -B /home/inb \
    $designer_container \
    designer \
    -denoise \
    $DWIconcatenated \
    $DWIdenoised
  else
    echolor $colorinfo "[INFO] Denoising with dwidenoise"
    my_do_cmd dwidenoise -nthreads $nthreads  \
              -estimator Exp2 $DWIconcatenated $DWIdenoised
  fi
  echo "[INFO] Copying bvals and bvecs for $DWIdenoised"
  cp -v $bval ${DWIdenoised%.nii.gz}.bval
  cp -v $bvec ${DWIdenoised%.nii.gz}.bvec
  bval=${DWIdenoised%.nii.gz}.bval
  bvec=${DWIdenoised%.nii.gz}.bvec

else
  echolor $colorinfo "[INFO] Denoised image exists, not overwriting $DWIdenoised"
fi



dwi=$DWIdenoised
echo "[INFO] Denoised data: $dwi $bvec $bval"

## mask
mask=${dwi%.nii.gz}_mask.nii.gz
if [ ! -f $mask ]
then
  echo "[INFO] Creating a mask"
  my_do_cmd dwi2mask -nthreads $nthreads \
    -fslgrad $bvec $bval \
    $dwi \
    $mask
  #mrconvert -coord 3 0 $dwi - | mrcalc - 0 -gt $mask
else
  echo "[INFO] Mask exists, not overwriting $mask"
fi


## mcflirt
if [ $doMotion -eq 1 ]
then
  echolor yellow "Running mcflirt"
  my_do_cmd mcflirt -in $dwi \
    -dof 6 \
    -refvol 0 \
    -o ${tmpDir}/dwi_mcf.nii.gz \
    -verbose 1 -report -plots -stats
  dwi=${tmpDir}/dwi_mcf.nii.gz 
fi


## eddy
echo "[INFO] eddy correction"
acqp=${dwi%.nii.gz}_acqp.txt
index=${dwi%.nii.gz}_index.txt
c4topup=0.0438;# this is just a guess
nvols=`fslnvols $dwi`
echo "0 -1 0" $c4topup > $acqp
indx=""
for ((i=1; i<=$nvols; i+=1)); do indx="$indx 1"; done
echo $indx > $index

if [ ! -f ${outbase}_de.nii.gz ]
then
  
  #info_dwi=$(mrinfo -spacing $dwi)
  #info_mask=$(mrinfo -spacing $mask)

  #if [ ! "$info_dwi" = "$info_mask" ]
  #then
  #  echolor red "[ERROR] Resolution mismatch between dwi and mask"
    mrinfo $dwi $mask
  #  exit 2
  #fi

  my_do_cmd eddy_cuda10.2 --verbose \
    --imain=$dwi \
    --mask=$mask \
    --acqp=$acqp \
    --index=$index \
    --bvecs=$bvec \
    --bvals=$bval \
    --residuals=true \
    --repol=true \
    --data_is_shelled \
    --flm=movement \
    --slm=linear \
    --cnr_maps \
    --fwhm=10,5,0,0,0 \
    --out=${outbase}_de


#   echo "[INFO] Running eddy quality check"
#   mrinfo ${outbase}_de.nii.gz
#   mrinfo $mask

# echolor cyan "check"  
# ls ${outbase}_de*

#   my_do_cmd eddy_quad \
#     ${outbase}_de \
#     -idx $index \
#     -par $acqp \
#     -m $mask \
#     -b $bval



  if [ $doScale -eq 1 ]
  then
      echolor yellow "Will scale back to original image voxel dimensions"
      my_do_cmd mrconvert -vox "${x},${y},${z}" ${outbase}_de.nii.gz /tmp/scale_$$_dwi_de.nii.gz
      mv -v /tmp/scale_$$_dwi_de.nii.gz ${outbase}_de.nii.gz

      my_do_cmd mrconvert -vox "${x},${y},${z}" $mask /tmp/scale_$$_mask.nii.gz
      mv -v /tmp/scale_$$_mask.nii.gz $mask
  fi


else
  echo "[INFO] Eddy-corrected image exists, not overwriting ${outbase}_de.nii.gz"
fi






echo "[INFO] Copying bvals and bvacs for ${outbase}_de"
cp -v $bval ${outbase}_de.bval
cp -v ${outbase}_de.eddy_rotated_bvecs  ${outbase}_de.bvec

echo "[INFO] Removing NaNs from ${outbase}_de.bvec"
sed -i 's/nan/0/g'  ${outbase}_de.bvec



## Bias field correction
minbvalue=`transpose_table.sh $bval | sort | uniq | sort -g | head -n 1 | tr -d '[:blank:]'`
echo ""
if [ ! -f ${outbase}_deb.nii.gz ]
then
  my_do_cmd dwiextract -nthreads $nthreads  \
    -fslgrad ${outbase}_de.bvec $bval    -shell $minbvalue \
    ${outbase}_de.nii.gz \
    ${tmpDir}/bzeros.nii
  my_do_cmd mrmath -axis 3 ${tmpDir}/bzeros.nii mean ${tmpDir}/avbzero.nii


mrinfo ${tmpDir}/avbzero.nii

  echo "[INFO] Copying sform to qform"
  my_do_cmd fslorient -copysform2qform ${tmpDir}/avbzero.nii
  my_do_cmd mrconvert $mask ${tmpDir}/mask.nii
  my_do_cmd fslorient -copysform2qform ${tmpDir}/mask.nii

echolor orange "Checking here for file ${tmpDir}/avbzero.nii"
ls ${tmpDir}/avbzero.nii
mrinfo ${tmpDir}/avbzero.nii


  echo "[INFO] Calculating bias field"
  my_do_cmd N4BiasFieldCorrection \
    -v \
    -d 3 \
    -i ${tmpDir}/avbzero.nii \
    -o [${tmpDir}/avbzero_corrected.nii,${tmpDir}/init_bias.nii] \
    -s 2 -b [10,3] -c [1000,0.0]
  echo "[INFO] Correcting for bias field"
  my_do_cmd mrcalc -nthreads $nthreads \
    ${outbase}_de.nii.gz \
    ${tmpDir}/init_bias.nii \
    -div ${outbase}_deb.nii.gz

  echo "[INFO] Copying bvals and bvacs for ${outbase}_deb"
  cp -v $bval ${outbase}_deb.bval
  cp -v ${outbase}_de.eddy_rotated_bvecs  ${outbase}_deb.bvec
else
  echo "[INFO] Biasfield-corrected image exists, not overwriting ${outbase}_deb.nii.gz"
fi

#    -w ${tmpDir}/mask.nii \


echo "[INFO] Moving intermediary outputs out of the way to ${outbase}_de.files/"
my_do_cmd mkdir ${outbase}_de.files
my_do_cmd mv ${outbase}_de.eddy_*  \
 ${tmpDir}/*.txt \
 ${DWIconcatenated%.nii.gz}* \
  ${outbase}_de.files/


# echo "[INFO] Generating some RGB maps for easy QC"
# for v in d de deb
# do
#   my_do_cmd dwi2tensor \
#     ${outbase}_${v}.nii.gz \
#     -mask ${outbase}_d_mask.nii.gz \
#     -fslgrad ${outbase}_${v}.bv{ec,al} ${tmpDir}/dt_${v}.nii
#   my_do_cmd tensor2metric -vector ${tmpDir}/v1_${v}.nii ${tmpDir}/dt_${v}.nii

#   for c in 0 1 2
#   do
#     mrconvert -coord 3 $c ${tmpDir}/v1_${v}.nii ${tmpDir}/chan${c}_${v}.nii
#     slices  ${tmpDir}/chan${c}_${v}.nii -o ${tmpDir}/chan${c}_${v}.gif -i 0 1
#   done

#   my_do_cmd convert ${tmpDir}/chan?_${v}.gif -combine ${outbase}_${v}_RGB.png
# done
# my_do_cmd montage -label "%f" ${outbase}_*_RGB.png -geometry +1+1 ${outbase}_RGBqc.png
#convert ${outbase}_deb_RGB.png ${outbase}_deb_RGB.pdf



if [ $keep_tmp -eq 0 ]
then
  echo "[INFO] Deleting directory: $tmpDir"
  my_do_cmd rm -fR $tmpDir
else
  echo "[INFO] Not deleting directory: $tmpDir"
fi 

echo "[INFO] Finished pre-processing."
