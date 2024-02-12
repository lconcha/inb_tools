#!/bin/bash
source `which my_do_cmd`
export FSLOUTPUTTYPE=NIFTI

multiframe_in=$1
average_out=$2

if [ -f $average_out ]; then echolor red "[INFO] Output file exists, will not overwrite";exit 0;fi



tmpDir=$(mktemp -d)

my_do_cmd mrconvert $multiframe_in ${tmpDir}/multiframe.nii
my_do_cmd fslsplit ${tmpDir}/multiframe.nii ${tmpDir}/frame_ -t

firstframe=${tmpDir}/firstframe.nii
mv -v ${tmpDir}/frame_0000.nii $firstframe

for f in ${tmpDir}/frame_*.nii
do
  echo "[INFO] Registering $f to $firstframe"
  my_do_cmd flirt \
    -in $f \
    -ref $firstframe \
    -out ${f%.nii}_reg.nii \
    -nosearch \
    -interp spline \
    -searchcost corratio
done

my_do_cmd mrcat  -axis 3 $firstframe ${tmpDir}/*reg.nii ${tmpDir}/regall.nii
my_do_cmd mrmath -axis 3 ${tmpDir}/regall.nii mean $average_out


rm -fR $tmpDir