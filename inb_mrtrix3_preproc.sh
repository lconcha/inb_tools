#!/bin/bash
source `which my_do_cmd`
FSLOUTPUTTYPE=NIFTI


if [ ! -f $mrtrixDir/bin/tckgen ]
then
  echo "ERROR: Not running mrtrix version 3. Please check your mrtrixDir dir."
  exit 2
fi



print_help()
{
  echo "
  `basename $0` <origDWIs> <grad.encoding> <shell> <mask> <outbase> [options]

Prepare DWIs for use in a quantitative FOD framework.

Will perform the following steps:

[STEP 1] Separate the b=0 images from the DWIs
[STEP 2] Run FAST to estimate B1 bias field from DWIs
[STEP 3] Compensate for magnet B1 bias field
[STEP 4] Estimate the tensor and FA map to construct an initial single fibre mask
[STEP 5] Obtain ratio of DWis to b=0 so that we can use similar signal intensities between subjects
[STEP 6] Estimate response function
[STEP 7] Organize results
[STEP 8] Remove tmp directory

Compulsory arguments are:
origDWIs      : The original DWI 4D data set
grad.encoding : Corresponding mrtrix-style gradient table
shell         : The b value to use (e.g. 1000)
mask          : A binary brain mask
outbase       : Outputs will have such prefix. 

Options:
-tmpDir <path>
-nthreads <int>
-keep_tmp


 LU15 (0N(H4
 INB, UNAM
 June 2014.
 lconcha@unam.mx


"
}



if [ $# -lt 5 ] 
then
  echo " ERROR: Need more arguments..."
  print_help
  exit 2
fi


###### Defaults
origDWIs=$1
grad=$2
shell=$3
mask=$4
outbase=$5
nthreads="" 
tmpDir=/tmp/mrtrix_preproc_`random_string`
keep_tmp=0
######## end defaults




declare -i index
index=1
flipOptions=""
for arg in "$@"
do
  case "$arg" in
    -h|-help) 
      print_help
      exit 1
    ;;
    -tmpDir)
      nextarg=`expr $index + 1`
      eval tmpDir=\${${nextarg}}
    ;;
    -nthreads)
      nextarg=`expr $index + 1`
      eval n=\${${nextarg}}
      nthreads="-nthreads $n"
    ;;
    -keep_tmp)
      keep_tmp=1
    ;;
  esac
  index=$[$index+1]
done





############################# BEGIN
mkdir -v $tmpDir


echo "
[STEP] Separate the b=0 images."
my_do_cmd dwiextract -quiet -grad $grad -bzero        $origDWIs ${tmpDir}/b0s.nii
nDim=`mrinfo -ndim ${tmpDir}/b0s.nii`
if [ $nDim -eq 3 ]
then
  echo "  There is only one b=0 image; no need to average."
  cp -v ${tmpDir}/b0s.nii ${tmpDir}/b0mean.nii
else
  my_do_cmd mrmath -quiet -axis 3 ${tmpDir}/b0s.nii mean ${tmpDir}/b0mean.nii
fi
my_do_cmd mrcalc -quiet ${tmpDir}/b0mean.nii $mask -mult ${tmpDir}/b0mean_masked.nii

my_do_cmd dwiextract -quiet -grad $grad -shell $shell $origDWIs ${tmpDir}/shell.nii
my_do_cmd mrmath -quiet -axis 3 ${tmpDir}/shell.nii mean ${tmpDir}/shellmean.nii
my_do_cmd mrcalc -quiet ${tmpDir}/shellmean.nii $mask -mult ${tmpDir}/shellmean_masked.nii





echo "
[STEP] Run FAST"
my_do_cmd  fast -v \
   -S 2 \
   -n 4 \
   --nopve -H 0.1 -I 4 -l 20.0 -b \
   -o ${tmpDir}/oFast \
   ${tmpDir}/b0mean_masked.nii \
   ${tmpDir}/shellmean_masked.nii




echo "
[STEP] Compensate for magnet B1 bias field"
my_do_cmd mrcalc -quiet \
  $origDWIs \
  ${tmpDir}/oFast_bias_2.nii \
  -divide \
  ${tmpDir}/dwi_biasCorr.nii






echo "
[STEP] Estimate the tensor and FA map"
my_do_cmd dwi2tensor $nthreads -method loglinear \
  -mask $mask \
  -grad $grad \
  ${tmpDir}/dwi_biasCorr.nii \
  ${tmpDir}/tensor.nii
my_do_cmd tensor2metric \
  -fa ${tmpDir}/fa.nii \
  ${tmpDir}/tensor.nii


echo "
[STEP] Estimate initial single fibre mask" 
maskfilter \
  $mask \
  -npass 3 \
  erode \
  - | \
  mrcalc -quiet \
  - \
  ${tmpDir}/fa.nii \
  0.65 \
  -gt \
  -multiply \
  ${tmpDir}/sf.nii

# echo "
# [STEP] ratio of DWis to b0"
# echo  "first get the mean b=0, because it has been bias corrected"
# my_do_cmd dwiextract -quiet -grad $grad -bzero ${tmpDir}/dwi_biasCorr.nii ${tmpDir}/b0s_bc.nii
# my_do_cmd mrmath -quiet -axis 3 ${tmpDir}/b0s_bc.nii mean ${tmpDir}/b0mean_bc.nii
# my_do_cmd mrcalc -quiet \
#    ${tmpDir}/dwi_biasCorr.nii  \
#    ${tmpDir}/b0mean_bc.nii \
#    -divide \
#    ${tmpDir}/dwi_biasCorr_ratios.nii

echo " 
# [STEP] ratio of DWis to average DWI value in single fibre mask"
avDWI_sf=`dwiextract -grad $grad -shell $shell ${tmpDir}/dwi_biasCorr.nii - \
  | mrmath -axis 3 - mean - \
  | mrstats -mask ${tmpDir}/sf.nii -output mean -`
echo "  mean value in DWIs (sf mask) = $avDWI_sf"
my_do_cmd mrcalc ${tmpDir}/dwi_biasCorr.nii \
                 $avDWI_sf \
                 -divide \
                 ${tmpDir}/dwi_biasCorr_ratios.nii


echo "
[STEP] Remove high-signal DWI_ratio noise and update mask" 
my_do_cmd dwiextract -quiet -grad $grad -shell $shell \
  ${tmpDir}/dwi_biasCorr_ratios.nii ${tmpDir}/shell_bc_ratios.nii
my_do_cmd mrmath -quiet -axis 3 \
  ${tmpDir}/shell_bc_ratios.nii mean \
  ${tmpDir}/mean_shell_bc_ratios.nii
mrcalc -quiet \
  ${tmpDir}/mean_shell_bc_ratios.nii \
  $mask -mult - | \
  mrcalc -quiet - 2 -gt ${tmpDir}/errors.nii
mrcalc  $mask ${tmpDir}/errors.nii \
  -subtract ${tmpDir}/updated_mask.nii
mask=${tmpDir}/updated_mask.nii



echo "
[STEP] Estimate response function."
my_do_cmd dwi2response $nthreads -info \
  -grad $grad \
  -mask ${tmpDir}/sf.nii \
  -max_change 0.5 \
  ${tmpDir}/dwi_biasCorr_ratios.nii \
  ${tmpDir}/response.txt




echo "
[STEP] Organize results"
my_do_cmd mrconvert -quiet $mask ${outbase}_mask.nii.gz
my_do_cmd mrcalc ${tmpDir}/mean_shell_bc_ratios.nii $mask -multiply ${outbase}_avDWI_ratios.nii.gz
my_do_cmd mrcalc -quiet ${tmpDir}/dwi_biasCorr_ratios.nii $mask -multiply ${outbase}_dwi_biasCorr_ratios.nii.gz
my_do_cmd mrconvert -quiet ${tmpDir}/oFast_bias_2.nii ${outbase}_dwi_bias_field.nii.gz
cp -v ${tmpDir}/response.txt ${outbase}_response.txt


if [ $keep_tmp -eq 0 ]
then
  echo "
  [STEP] Remove tmp directory."
  rm -fR $tmpDir
else
  echo "[INFO] Did not remove tmpDir: $tmpDir "
fi

echo "You can now estimate the FODs, just type:
  dwi2fod -grad $grad -mask ${outbase}_mask.nii.gz ${outbase}_dwi_biasCorr_ratios.nii.gz ${outbase}_response.txt ${outbase}_FOD.nii.gz
"
echo "Done." 