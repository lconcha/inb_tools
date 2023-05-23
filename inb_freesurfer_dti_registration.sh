#!/bin/bash
source `which my_do_cmd`

subject=$1
useFSL=0
fakeflag=""
print_help()
{
echo "
`basename $0` <subjid> [options]

Options:
-b0                        Register T1 against b0 (default is to FA)
-iterations <intxintxint>  Default is 8x4x0
-fake
-flair                     Register FLAIR to avDWI.
                           Requires: subject/dti/avDWI.nii.gz (the average b>0)
                                     subject/mri/flair.nii.gz
                           Both the avDWI and flair volumes _must_ be skull stripped and fslreorient2std

Luis Concha
INB
2012

Modifications:
December 2013. Added the flair to avDWI registration method (uses fnirt).
"

}


if [ $# -lt 1 ] 
then
  echo "  ERROR: Need more arguments..."
  print_help
  exit 1
fi


reg_to_b0=0
iterations=8x4x0
hasFLAIR=0
declare -i i
i=1
for arg in "$@"
do
  case "$arg" in
  -h|-help) 
    print_help
    exit 1
  ;;
  -b0)
    reg_to_b0=1
  ;;
  -iterations)
    nextarg=`expr $i + 1`
    eval iterations=\${${nextarg}}
  ;; 
  -flair)
    hasFLAIR=1
  ;;
  -fake)
    fakeflag="-fake"
    echo "Just a fake!"
  ;;
  esac
  i=$[$i+1]
done





FSLOUTPUTTYPE=NIFTI


# this script expects that the structure of the data is as follows:
# $SUBJECTS_DIR/$subject/mri/brain.mgz
# $SUBJECTS_DIR/$subject/dti/dti.nii
# $SUBJECTS_DIR/$subject/dti/dti.bval
# $SUBJECTS_DIR/$subject/dti/dti.bvec
# $SUBJECTS_DIR/$subject/mri/flair.nii.gz


# these MUST exist for the non-flair version
t1=$SUBJECTS_DIR/$subject/mri/brain.mgz
dti=$SUBJECTS_DIR/$subject/dti/dti.nii
bval=$SUBJECTS_DIR/$subject/dti/dti.bval
bvec=$SUBJECTS_DIR/$subject/dti/dti.bvec


# these may exist
b0=$SUBJECTS_DIR/$subject/dti/nodif.nii
b0mask=$SUBJECTS_DIR/$subject/dti/nodif_brain_mask.nii
fa=$SUBJECTS_DIR/$subject/dti/dti_fa



tmpDir=$SUBJECTS_DIR/$subject/tmp/dtireg
mkdir -p $tmpDir






####### FLAIR version (good!)
if [ $hasFLAIR -eq 1 ]
then
  flair=$SUBJECTS_DIR/$subject/mri/flair.nii.gz
  avDWI=$SUBJECTS_DIR/$subject/dti/avDWI.nii.gz 
  #note that avDWI must already be reoriented to std and skull-stripped
  

  flairRegOK=1
  for f in $flair $avDWI
  do
     if [ ! -f $f ]
     then
      echo "Fatal Error. File does not exist: $f"
      flairRegOK=0
     fi
  done
  if [ $flairRegOK -eq 0 ]
  then
    exit 2
  fi

 
  
## Linear xfm between flair and avDWI
  if [ -f $SUBJECTS_DIR/$subject/mri/flair_to_avDWI_lin.mat ]
  then
    echo "WARNING: Linear xfm (Flair to avDWI) already exists."
  else
    my_do_cmd flirt \
            -in $flair \
            -ref $avDWI \
            -omat $SUBJECTS_DIR/$subject/mri/flair_to_avDWI_lin.mat
  fi

## Non-linear warp between flair and avDWI
  if [ -f $SUBJECTS_DIR/$subject/dti/flair_to_avDWI_nlin_warpField.ni* ]
  then
     echo "WARNING: Warp field (Flair to avDWI) already exists."
  else

     my_do_cmd fnirt -v \
            --in=$flair \
            --ref=$avDWI \
            --aff=$SUBJECTS_DIR/$subject/mri/flair_to_avDWI_lin.mat \
            --iout=$SUBJECTS_DIR/$subject/dti/flair_to_avDWI_nlin \
            --cout=$SUBJECTS_DIR/$subject/dti/flair_to_avDWI_nlin_fieldCoefs \
            --fout=$SUBJECTS_DIR/$subject/dti/flair_to_avDWI_nlin_warpField

  fi
  

  my_do_cmd mri_convert $t1 ${tmpDir}/t1.nii
  my_do_cmd fslreorient2std ${tmpDir}/t1.nii ${tmpDir}/t1_r.nii
  t1=${tmpDir}/t1_r.nii
  

 ## Linear xfm between t1 and flair
  xfm_flair_to_t1=$SUBJECTS_DIR/$subject/mri/flair_to_t1_lin.mat
  if [ -f $xfm_flair_to_t1 ]
  then
     echo "WARNING: Linear xfm (flair to T1) already exists: $xfm_flair_to_t1"
  else
     my_do_cmd flirt \
            -in $t1 \
            -ref $flair \
            -omat $xfm_flair_to_t1 \
            -out $SUBJECTS_DIR/$subject/mri/t1_to_flair_lin
  fi

 
  ## Concatenate all transformations so that we can go from t1 to avDWI throught flair.
  warp_t1_to_flair_to_avDWI=$SUBJECTS_DIR/$subject/dti/t1_to_flair_to_avDWI_nlin_warpField
  my_do_cmd  convertwarp \
         --ref=$avDWI \
         --premat=$xfm_flair_to_t1 \
         --warp1=$SUBJECTS_DIR/$subject/dti/flair_to_avDWI_nlin_warpField \
         --out=$warp_t1_to_flair_to_avDWI

 
 ## apply the transformations!
 for f in brain aparc.a2009s+aseg aparc+aseg
 do
    my_do_cmd mri_convert $SUBJECTS_DIR/$subject/mri/${f}.mgz \
              ${tmpDir}/`basename ${f}`.nii
    my_do_cmd fslreorient2std ${tmpDir}/`basename ${f}`.nii \
              ${tmpDir}/`basename ${f}`_r
    my_do_cmd applywarp \
	  --in=${tmpDir}/`basename ${f}`_r \
	  --out=$SUBJECTS_DIR/$subject/dti/`basename ${f}`_to_avDWI \
	  --ref=$avDWI \
	  --interp=nn \
	  --warp=$warp_t1_to_flair_to_avDWI
 done


  ## clean up, clean up... everybody, everywhere...
  gzip -v $SUBJECTS_DIR/$subject/dti/*.nii
  rm -fR $tmpDir
  exit 1
fi
############## End FLAIR version























# If we did not do the FLAIR version, then we still have the b0-FA version.


if [ ! -f $b0 ]
then
  echo " | Extract the b=0 image"
  idx=`transpose_table.sh $bval | grep -n ^0 | awk -F: '{print $1}' | head -n 1`
  my_do_cmd $fakeflag fslroi $dti $b0 $(( $idx - 1 )) 1
fi

if [ ! -f $b0mask ]
then
  my_do_cmd $fakeflag bet $b0 $b0mask -f 0.25
fi


if [ $reg_to_b0 -eq 1 ]
then
  b0masked=$SUBJECTS_DIR/$subject/dti/nodif_masked.nii
  my_do_cmd $fakeflag fslmaths $b0mask -bin -mul $b0 $b0masked
fi


if [ `imtest $fa` -eq 0 ]
then
  echo " | Computing tensor"
  my_do_cmd $fakeflag inb_mrtrix_proc.sh \
			$dti \
			${dti%.nii}_encoding.b \
			$SUBJECTS_DIR/$subject/dti/dti \
			-nii -noCSD
fi




# erode the FA map a little
my_do_cmd $fakeflag fslmaths $b0mask -ero -ero ${tmpDir}/b0mask_eroded.nii
my_do_cmd $fakeflag fslmaths -dt float $fakeflag $fa -mul ${tmpDir}/b0mask_eroded.nii ${tmpDir}/fa_eroded.nii -odt float
cp -v ${tmpDir}/b0mask_eroded.nii $SUBJECTS_DIR/$subject/dti/dti_b0mask_eroded.nii
fa=${tmpDir}/fa_eroded.nii



echo " | Prepare files for registration"
my_do_cmd $fakeflag mri_convert $t1 ${tmpDir}/t1.nii
t1=${tmpDir}/t1.nii
my_do_cmd $fakeflag bet $t1 ${tmpDir}/t1_bet.nii
t1=${tmpDir}/t1_bet.nii
my_do_cmd $fakeflag fslreorient2std $t1 ${tmpDir}/t1_bet_r.nii
t1=${tmpDir}/t1_bet_r.nii
my_do_cmd $fakeflag fslreorient2std $fa ${tmpDir}/fa_bet_r.nii
fa=${tmpDir}/fa_bet_r.nii

TARGET=$fa
if [ $reg_to_b0 -eq 1 ]
then
  my_do_cmd $fakeflag fslreorient2std $b0masked ${tmpDir}/b0_bet_r.nii
  b0masked=${tmpDir}/b0_bet_r.nii
  TARGET=$b0masked
fi


echo " | Coregister the t1 to the FA using a non-linear transform."
outbase=$SUBJECTS_DIR/$subject/dti/ants_t1_to_fa
if [ -f ${outbase}Warpxvec.nii.gz ]
then
  echo "  Warp found: ${outbase}Warpxvec.nii.gz"
  echo "  Not overwriting"
else
  my_do_cmd $fakeflag ANTS 3 \
    -m  MI[$TARGET,$t1,1,32] \
    -t  SyN[1,2,0.05] \
    --geodesic 2  \
    -r Gauss[3,0.] \
    -o $outbase \
    -i $iterations \
    --use-Histogram-Matching  \
    --number-of-affine-iterations 10000x10000x10000x10000x10000 \
    --MI-option 32x16000
fi

# Resample the t1 to DTI native space
my_do_cmd $fakeflag WarpImageMultiTransform 3 \
  $t1 \
  $SUBJECTS_DIR/$subject/dti/t1_native_dti_space.nii \
  ${outbase}Warp.nii.gz ${outbase}Affine.txt  \
  -R $fa


# Resample the automatic parcellation to DTI native space
for segmentation in aparc.a2009s+aseg aparc+aseg
do
  my_do_cmd $fakeflag mri_convert $SUBJECTS_DIR/$subject/mri/${segmentation}.mgz \
				  ${tmpDir}/aparc.nii
  my_do_cmd $fakeflag WarpImageMultiTransform 3 \
    ${tmpDir}/aparc.nii \
    $SUBJECTS_DIR/$subject/dti/${segmentation}_native_dti_space.nii \
    ${outbase}Warp.nii.gz ${outbase}Affine.txt  \
    -R $fa \
    --use-NN
done

rm -fR $tmpDir