#!/bin/bash


atlasdir=/datos/syphon/lconcha/software/Fischer344atlas/Fischer344_nii_v4


function help(){
echo "
`basename $0` <-i movingimage> <-o outbase> [-d atlasdir]


Registration of an anatomical image to Fischer344 rat atlas.



-i movingimage    Image to move register into atlas space.
                  Should already have been bias field corrected, but one more correction
                  will be performed using the resulting mask.
                  
-o outbase        Prefix for outputs:
                  _toatlas.mat  (affine registration to atlas).
                  _mask.nii.gz  (brain mask in native space)
                  _bcorr.nii.gz (input image now with one more bias field correction)


Options:

-d atlasdir       The full path to the atlas containing Fischer344_template.nii
                  Currently: $atlasdir
-n                Perform non-linear registration (takeas a long time but results are amazing)
-t                Specify temporal directory
-k                Do not delete temporal directory
-h                Show this help.
                  

LU15 (0N(H4
(inspired and assisted by Eduardo Garza)
INB-UNAM
Feb 2022
lconcha@unam.mx
"
}


dononlinear=0
tmpdir=""
keep_tmp=0
while getopts i:o:d:nt:kh flag
do
    case "${flag}" in
        i) movingfile=${OPTARG};;
        o) outbase=${OPTARG};;
        d) atlasdir=${OPTARG};;
        n) dononlinear=1;;
        t) tmpdir=${OPTARG};;
        k) keep_tmp=1;;
        h) help;exit 2;;
    esac
done



if [ -z "$movingfile" -o -z "${outbase}" -o -z "${atlasdir}" ]
then
    echolor red "[ERROR] Incorrect inputs"
    help; exit 2
fi
if [ ! -f $movingfile ]
then
    echolor red "[ERROR] Cannot find input: $movingfile"
    help; exit 2
fi





#Model for brainmask
fixedfile=${atlasdir}/Fischer344_template.nii
fixedmask=${atlasdir}/Fischer344_template_mask.nii
isOK=1
for f in $fixedfile $fixedmask
do
    if [ ! -f $f ]
    then
        echolor red "[ERROR] Cannot find $f"
        isOK=0
    fi
done


if [ $isOK -eq 0 ]
then
  exit 2
fi

#######################################


set -x
if [ -d "${tmpdir}" ]
then
  echolor cyan "[INFO] Using user-specified tmpdir: $tmpdir"
else
  echolor cyan "[INFO] tmpdir does not exist."
  tmpdir=$(mktemp -d)
  echolor cyan "[INFO] Creating a temp directory in $tmpdir"
fi


if [ ! -f ${tmpdir}/atlasmask2native_affine_dilated.nii ]
then
  movingmask=NOMASK
  #Optimized multi-stage affine registration
  echolor yellow "[INFO] First registration pass without native mask"
  antsRegistration --dimensionality 3 --verbose \
  --use-histogram-matching 0 \
  --output [ ${tmpdir}/reg1_ ] \
  --initial-moving-transform [${fixedfile},${movingfile},1 ] \
  --winsorize-image-intensities [ 0.005,0.995 ] \
  --transform Translation[ 0.1 ] \
          --metric Mattes[ ${fixedfile},${movingfile},1,43,None ] \
          --convergence [ 2025x2025x2025x2025x1350,1e-6,10 ] \
          --shrink-factors 6x6x6x5x4 \
          --smoothing-sigmas 0.407674464138x0.356715156121x0.305755848104x0.254796540086x0.203837232069mm \
          --masks [ NOMASK,NOMASK ] \
  --transform Rigid[ 0.1 ] \
          --metric Mattes[ ${fixedfile},${movingfile},1,51,None ] \
          --convergence [ 2025x1350x450,1e-6,10 ] \
          --shrink-factors 5x4x3 \
          --smoothing-sigmas 0.254796540086x0.203837232069x0.152877924052mm \
          --masks [ NOMASK,NOMASK ] \
  --transform Similarity[ 0.1 ] \
          --metric Mattes[ ${fixedfile},${movingfile},1,64,None ] \
          --convergence [ 1350x450x150,1e-6,10 ] \
          --shrink-factors 4x3x2 \
          --smoothing-sigmas 0.203837232069x0.152877924052x0.101918616035mm \
          --masks [ NOMASK,NOMASK ] \
  --transform Similarity[ 0.1 ] \
          --metric Mattes[ ${fixedfile},${movingfile},1,64,None ] \
          --convergence [ 1350x450x150,1e-6,10 ] \
          --shrink-factors 4x3x2 \
          --smoothing-sigmas 0.203837232069x0.152877924052x0.101918616035mm \
          --masks [ ${fixedmask},${movingmask} ] \
  --transform Affine[ 0.1 ] \
          --metric Mattes[ ${fixedfile},${movingfile},1,64,None ] \
          --convergence [ 1350x450x150x50x50,1e-6,10 ] \
          --shrink-factors 4x3x2x1x1 \
          --smoothing-sigmas 0.203837232069x0.152877924052x0.101918616035x0.0509593080173x0mm \
          --masks [ ${fixedmask},${movingmask} ]
          
          
  # transform the atlas mask to the native image        
  antsApplyTransforms -d 3 \
    -i $fixedmask \
    -r $movingfile \
    -t [${tmpdir}/reg1_0GenericAffine.mat,1] \
    -o ${tmpdir}/atlasmask2native_affine.nii
    
  maskfilter -quiet -npass 1 \
    ${tmpdir}/atlasmask2native_affine.nii \
    dilate \
    ${tmpdir}/atlasmask2native_affine_dilated.nii
else
  echolor cyan "[INFO] File exists: ${tmpdir}/atlasmask2native_affine_dilated.nii"
fi
  
  


#Optimized multi-stage affine registration
if [ ! -f ${tmpdir}/atlasmask2native_reg2.nii ]
then
echolor yellow "[INFO] Second registration, now with native mask"
movingmask=${tmpdir}/atlasmask2native_affine_dilated.nii
antsRegistration --dimensionality 3 --verbose \
--use-histogram-matching 0 \
--output [ ${tmpdir}/reg2_ ] \
--initial-moving-transform ${tmpdir}/reg1_0GenericAffine.mat \
--winsorize-image-intensities [ 0.005,0.995 ] \
--transform Similarity[ 0.1 ] \
        --metric Mattes[ ${fixedfile},${movingfile},1,64,None ] \
        --convergence [ 1350x450x150,1e-6,10 ] \
        --shrink-factors 4x3x2 \
        --smoothing-sigmas 0.203837232069x0.152877924052x0.101918616035mm \
        --masks [ ${fixedmask},${movingmask} ] \
--transform Affine[ 0.1 ] \
        --metric Mattes[ ${fixedfile},${movingfile},1,64,None ] \
        --convergence [ 1350x450x150x50x50,1e-6,10 ] \
        --shrink-factors 4x3x2x1x1 \
        --smoothing-sigmas 0.203837232069x0.152877924052x0.101918616035x0.0509593080173x0mm \
        --masks [ ${fixedmask},${movingmask} ]
        

antsApplyTransforms -d 3 \
  -i $fixedmask \
  -r $movingfile \
  -t [${tmpdir}/reg2_0GenericAffine.mat,1] \
  -o ${tmpdir}/atlasmask2native_reg2.nii
else
  echolor cyan "[INFO] File exists: ${tmpdir}/atlasmask2native_reg2.nii"
fi


if [ ! -f ${tmpdir}/native_biascorrectedwithmask.nii ]
then
echolor yellow "[INFO] N4 correction"
N4BiasFieldCorrection -d 3 \
  -s 2 \
  -i $movingfile \
  -b [30] \
  -c [200x200x200,0.0] \
  -r 1 \
  -w ${tmpdir}/atlasmask2native_reg2.nii \
  -x ${tmpdir}/atlasmask2native_reg2.nii \
  -o [${tmpdir}/native_biascorrectedwithmask.nii,${tmpdir}/native_biasfieldwithmask.nii]
  

mrconvert -force -quiet  ${tmpdir}/native_biascorrectedwithmask.nii ${outbase}_bcorr.nii.gz
mrconvert -force -quiet  ${tmpdir}/atlasmask2native_reg2.nii        ${outbase}_mask.nii.gz
cp        ${tmpdir}/reg2_0GenericAffine.mat          ${outbase}_toatlas.mat
else
  echolor cyan "[INFO] FIle exists: ${tmpdir}/native_biascorrectedwithmask.nii"
fi


# non-linear registration
if [ $dononlinear -eq 1 ]
then
    echolor yellow "[INFO] Doing non-linear registration, this takes quite a while."

    mrcalc -force -quiet \
      $fixedfile $fixedmask -mul \
      ${tmpdir}/atlas_masked.nii
    mrcalc -force -quiet \
      ${outbase}_bcorr.nii.gz ${outbase}_mask.nii.gz -mul \
      ${tmpdir}/anat_masked.nii 
    antsRegistrationSyN.sh \
      -d 3 \
      -m ${tmpdir}/anat_masked.nii \
      -f ${tmpdir}/atlas_masked.nii \
      -o ${outbase}_nlin_ \
      -n $(nproc) \
      -t s

  antsApplyTransforms -d 3 \
    -i $fixedmask \
    -r $movingfile \
    -t [${outbase}_nlin_0GenericAffine.mat,1] \
    -t [${outbase}_nlin_1InverseWarp.nii.gz,0] \
    -o ${outbase}_nlin_mask.nii.gz \
    --interpolation NearestNeighbor

  mrcalc -force -quiet \
    ${outbase}_bcorr.nii.gz ${outbase}_nlin_mask.nii.gz -mul \
    ${tmpdir}/anat_nlin_masked.nii 

  N4BiasFieldCorrection -d 3 \
  -s 2 \
  -i ${tmpdir}/anat_nlin_masked.nii  \
  -b [30] \
  -c [200x200x200,0.0] \
  -r 1 \
  -w ${outbase}_nlin_mask.nii.gz \
  -x ${outbase}_nlin_mask.nii.gz \
  -o [${outbase}_native_nlin_biascorrected.nii.gz,${tmpdir}/native_nlin_biasfield.nii.gz]
  


fi

ls $tmpdir

if [ $keep_tmp -eq 0 ]
then
  rm -fR $tmpdir
else
  echolor cyan "[INFO] Temporary directory not deleted: $tmpdir"
fi
