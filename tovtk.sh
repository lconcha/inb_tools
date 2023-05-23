#!/bin/bash

source ~/noelsoft/BashTools/my_do_cmd
converter=~/software/irtk/convert


print_help()
{
  echo "
  `basename $0` <input_image> <output_vtk> [-options]

  Options:
   -help
   -fmt <format>  : where format can be char|uchar|short|ushort|float|double

  Luis Concha
  INB
  August 2011			
"
}



if [ $# -lt 2 ] 
then
  echo "  ERROR: Need more arguments..."
  print_help
  exit 1
fi

###########################
input=$1
output_vtk=$2
##########################
tmpdir=/tmp/$$_converter
mkdir $tmpdir


declare -i index
index=1
format=float
for arg in "$@"
do
  case "$arg" in
  -h|-help) 
    print_help
    exit 1
  ;;
  -fmt)
    nextArg=$(($index + 1))
    eval format=\$$nextArg
  ;;
  esac
  index=$[$index+1]
done


# Check that we have the converter
if [ ! -f $converter ]
then
  echo "ERROR: Cannot find $converter"
  echo "Fix it and come back."
  exit 1
fi


# Check if it is a format we cannot handle
datatype=`fslinfo $input | head -n 1 | awk '{print $2}'`
if [ "$datatype" == "INT32" ]
then
  echo "Converting your $datatype format input to float first..."
  export FSLOUTPUTTYPE=NIFTI
  my_do_cmd fslmaths $input -mul 1 ${tmpdir}/input -odt float
  input=${tmpdir}/input.nii
fi


my_do_cmd   $converter $input $output_vtk -$format

rm -fR $tmpdir



