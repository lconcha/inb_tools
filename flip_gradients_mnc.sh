#!/bin/bash


mnc=$1
bvals=/tmp/$$.bvals
bvecs=/tmp/$$.bvecs


isZipped=0
if [ -n "`echo ${mnc} | grep .gz`" ]
then
  isZipped=1
fi

if [ $isZipped -eq 1 ]
then
  echo "file is zipped"
  gunzip -v $mnc
  mnc=${mnc%.gz}
fi


arguments=""
for arg in "$@"
do

	case "$arg" in
		-h|-help) 
		echo "Luis Concha - INB"
		echo "Julio 2010"
		echo ""
		exit 1
		;;
	   -flip_x)
		arguments="$arguments -flip_x"
		;;
	   -flip_y)
		arguments="$arguments -flip_y"
		;;
	   -flip_z)
		arguments="$arguments -flip_z"
		;;
	esac
done


getGradientDirs.sh $mnc -bvec $bvecs -bval $bvals

flip_gradients.sh $bvecs ${bvecs}_flipped $arguments


dti_add_bval_bvec.sh $mnc $bvals ${bvecs}_flipped


if [ $isZipped -eq 1 ]
then
  echo zipping...
  gzip -v $mnc
fi

echo Done!