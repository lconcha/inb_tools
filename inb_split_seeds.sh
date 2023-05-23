#!/bin/bash

print_help()
{
  echo "
  `basename $0` <seeds.nii[.gz]> <output_base>

  
  Luis Concha
  INB, UNAM
  October, 2012.			
"
}


if [ $# -lt 2 ] 
then
  echo " ERROR: Need more arguments..."
  print_help
  exit 1
fi



declare -i i
i=1
skip=1
for arg in "$@"
do
  case "$arg" in
    -h|-help) 
      print_help
      exit 1
    esac
    i=$[$i+1]
done


seeds=$1
output_base=$2

echo "OCTAVE: octave --eval inb_split_seeds('$seeds','$output_base')"
octave --eval "inb_split_seeds('$seeds','$output_base')"
