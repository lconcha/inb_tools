#!/bin/bash


# Transform an anatomical T1 into DTI space
# It assumes that only the FA map is brain-extracted, while the T1 is not.


t1=$1
fa=$2
outbase=$3

xfm=${outbase}_t1_to_dti.tMatrix
t1coreg=${outbase}_t1_to_dti.nii.gz

tmpbase=tmp_


# Do the brain extraction of the T1
echo "  Extracting the brain from $t1" 
bet $t1 ${tmpbase}t1bet -f 0.25



echo "  Calculating xfm $xfm"
flirt -ref ${tmpbase}t1bet.nii.gz \
      -in $fa \
      -cost normmi \
      -searchcost normmi \
      -dof 12 \
      -omat ${outbase}_dti_to_t1.tMatrix

convert_xfm -omat $xfm -inverse ${outbase}_dti_to_t1.tMatrix

# echo "Calculating non linear warp"
# fnirt --ref=$fa \
#      --in=${tmpbase}t1bet.nii.gz \
#      --aff $xfm \
#      --cout=${t1coreg%.nii.gz}_coefs \
#      --iout=$t1coreg \
#      --fout=${t1coreg%.nii.gz}_field.nii.gz

echo "  Resampling to $t1coreg"
flirt -in $t1 \
     -ref $fa \
     -applyxfm -init $xfm \
     -out $t1coreg


rm ${tmpbase}*