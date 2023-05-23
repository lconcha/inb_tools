#!/bin/bash
source `which /my_do_cmd`

t1=$1
t2=$2
b0=$3
outbase=$4


tmpbase=inb_tmp_

echo " 1. Register the t2 to the b0"
my_do_cmd inb_transform_t2_to_b0.sh $t2 $b0 ${tmpbase}
cp -v  ${tmpbase}_t2_to_dti.tMatrix  ${outbase}_t2_to_dti.tMatrix


echo " 2. Register the t1 to the t2"
my_do_cmd flirt -cost normmi \
  -searchcost normmi \
  -in $t1 \
  -ref $t2 \
  -omat ${tmpbase}_t1_to_t2.tMatrix
cp -v ${tmpbase}_t1_to_t2.tMatrix ${outbase}_t1_to_t2.tMatrix


echo " 3. Concatenate the two xfms"
xfm=${outbase}_t1_to_t2_to_b0.tMatrix
my_do_cmd convert_xfm -omat $xfm -concat ${tmpbase}_t2_to_dti.tMatrix ${tmpbase}_t1_to_t2.tMatrix



echo " 4. Resample t1 to b0 using the concatenated xfm"
t1r=${outbase}_t1_to_t2_to_b0.nii.gz
my_do_cmd flirt -in $t1 \
      -ref $b0 \
      -applyxfm -init $xfm \
      -out $t1r

rm ${tmpbase}*