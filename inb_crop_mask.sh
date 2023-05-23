#!/bin/bash

mask=$1
outMask=$2
gap=$3



function help() {
echo "
  `basename $0` <mask> <maskOUT> <padding>

Crop a binary mask according to its bounding box and pad it.
Padding is expressed in voxels.

example:
  `basename $0` hippocampus.nii.gz croppedHippocampus.nii.gz 3


LU15 (0N(H4
Oct, 2015
INB, UNAM

"
}



if [ "$#" -lt 3 ]; then
  echo "[ERROR] - Not enough arguments"
  help
  exit 2
fi


declare -i i
i=1
verbose=1
for arg in "$@"
do
  case "$arg" in
  -h|-help) 
    help
    exit 1
  ;;
  esac
  i=$[$i+1]
done


bbox=`fslstats $mask -w`
echo "Original bounding box: $bbox"
read -a Abbox <<<$bbox


xstart=`echo "${Abbox[0]} - $gap" | bc `
ystart=`echo "${Abbox[2]} - $gap" | bc `
zstart=`echo "${Abbox[4]} - $gap" | bc `
xlen=`echo "${Abbox[1]} + $gap + $gap" | bc `
ylen=`echo "${Abbox[3]} + $gap + $gap" | bc `
zlen=`echo "${Abbox[5]} + $gap + $gap" | bc `


echo "Padded bounding box: $xstart $xlen $ystart $ylen $zstart $zlen"



fslroi $mask $outMask $xstart $xlen $ystart $ylen $zstart $zlen