#!/bin/bash


print_help() {
  echo "
  Convert a dicom directory with DTI data (one data set) into a minc file 
  that has all the gradient directions inside the header ready to use by
  mincDTIwrapper.sh
  
  use:
  
  `basename $0` dicomDirectory dti.mnc
  
"
}


if [ $# -lt 1 ] 
then
	print_help
	exit 1
fi


declare -i i
for arg in "$@"
do
   case "$arg" in
	-help)
		print_help
		exit 1
	;;
	esac
   i=`expr $i + 1`
done


dicomDIR=$1
dti_mnc=$2



rs=`random_string`
tmpDir=/tmp/${rs}
mkdir $tmpDir

dcm2nii -o $tmpDir -g n $dicomDIR

dti_nii=`ls ${tmpDir}/*.nii`
ls $tmpDir
if [ -f $dti_nii ]
then
  nii2mnc $dti_nii $dti_mnc
else
  echo "
        ERROR
       "
  echo "Cannot find $dti_nii"
  exit 1
fi

bvec=${dti_nii%.nii}.bvec
bval=${dti_nii%.nii}.bval

if [ -f $bvec ]
then
  echo Found $bvec
else
  echo "
        ERROR
       "
  echo "Cannot find bvec: $bvec"
  exit 1
fi

if [ -f $bval ]
then
  echo Found $bval
else
  echo "
        ERROR
       "
  echo "Cannot find bvec: $bval"
  exit 1
fi


dti_add_bval_bvec.sh $dti_mnc $bval $bvec

gzip $dti_mnc

rm -fR $tmpDir