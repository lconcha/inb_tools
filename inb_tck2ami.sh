#!/bin/bash

tck=$1
ami=$2
im=$3

#MATLAB_COMMAND=/home/inb/lconcha/fmrilab_software/MATLAB/Matlab13-alt/bin/matlab
MATLAB_COMMAND=/home/inb/soporte/fmrilab_software/MatlabR2018a/bin/matlab

print_help()
{
echo "
`basename $0` <track.tck> <track.ami> [image.nii]

Convert mrtrix tck streamlines to amira format.

The first two arguments are compulsory.

An optional image can be passed as a third argument,
from which the strealines were derived (e.g., fa.nii).
Voxel to world coordinates are taken from the .nii header.

Please note that by default track coordinates are in voxel space,
but this may actually work better in some cases.

LU15 (0N(H4
INB, UNAM
lconcha@unam.mx
December 2014.

"
}


declare -i i
i=1
for arg in "$@"
do
  case "$arg" in
  -h|-help)
    print_help
    exit 1
  ;;
  esac
  i=$[$i+1]
done



if [ $# -lt 2 ]
then
	echo " ERROR: Need more arguments..."
	print_help
	exit 1
fi





if [ -z $im ]
then
  job="tck2amira('$tck','$ami')"
else
  job="tck2amira('$tck','$ami','$im')"
fi

echo $job
$MATLAB_COMMAND -nodisplay <<EOF
$job
EOF
