#!/bin/bash


# Transform an anatomical T2 into DTI space
# It assumes that only the b0 map is brain-extracted, while the T2 is not.


t2=$1
b0=$2
outbase=$3

xfm=${outbase}_t2_to_dti.tMatrix
t2coreg=${outbase}_t2_to_dti.nii.gz

tmpbase=tmp_


# Do the brain extraction of the T1
echo "  Extracting the brain from $t2" 
bet $t2 ${tmpbase}t1bet -f 0.35



echo "  Calculating xfm $xfm"
flirt -ref ${tmpbase}t1bet.nii.gz \
      -in $b0 \
      -cost mutualinfo \
      -searchcost mutualinfo \
      -dof 12 \
      -omat ${outbase}_dti_to_t2.tMatrix

convert_xfm -omat $xfm -inverse ${outbase}_dti_to_t2.tMatrix

# echo "Calculating non linear warp"
# fnirt --ref=$fa \
#      --in=${tmpbase}t1bet.nii.gz \
#      --aff $xfm \
#      --cout=${t1coreg%.nii.gz}_coefs \
#      --iout=$t1coreg \
#      --fout=${t1coreg%.nii.gz}_field.nii.gz

echo "  Resampling to $t2coreg"
flirt -in $t2 \
     -ref $b0 \
     -applyxfm -init $xfm \
     -out $t2coreg


rm ${tmpbase}*