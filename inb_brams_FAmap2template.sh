#!/bin/bash
source `which my_do_cmd`




FAsubject=$1
outbase=$2
ROIs=$3
template=/usr/share/data/fsl-mni152-templates/FMRIB58_FA_1mm.nii.gz
#fakeflag="-fake"
fakeflag=""

xfm_atlas2subject=${outbase}_atlas2subject.mat

if [ -f ${outbase}Warpzvec.nii.gz ]
then
  echo "Already computed xfm"
else
  my_do_cmd $fakeflag antsIntroduction.sh -d 3 -i $template -r $FAsubject -o $outbase -s PR -t SY 

fi


FSLOUTPUTTYPE=NIFTI

cat $ROIs | while read roi
do
  #my_do_cmd $fakeflag flirt \
  #                          -ref $FAsubject \
  #                          -in $roi \
  #                          -applyxfm -init $xfm_atlas2subject \
  #                          -out ${outbase}_`basename $roi` \
  #                          -interp nearestneighbour

  my_do_cmd $fakeflag WarpImageMultiTransform 3 \
            ${roi} \
            ${outbase}_`basename $roi` \
            -R $FAsubject \
            --use-NN \
            ${outbase}Affine.txt \
            ${outbase}Warp
done