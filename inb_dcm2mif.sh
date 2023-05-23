#!/bin/bash

dicomdir=$1
mif=$2



print_help()
{
  echo "
  `basename $0` <dicomdir> <out.mif> [-Options]

  Options:
  
  -flip_x
  -flip_y
  -flip_z

  Luis Concha
  INB
  Jan 2011			
"
}



if [ $# -lt 2 ] 
then
  echo " ERROR: Need more arguments..."
  print_help
  exit 1
fi




declare -i index
index=1
flipOptions=""
for arg in "$@"
do

	case "$arg" in
		-h|-help) 
		print_help
                exit 1
		;;
	   -flip_x)
		flipOptions="${flipOptions} -flip_x"
		;;
	   -flip_y)
		flipOptions="${flipOptions} -flip_y"
		;;
	   -flip_z)
		flipOptions="${flipOptions} -flip_z"
		;;
	esac
	index=$[$index+1]
done




# remove trailing slash
dicomdir=`echo "${dicomdir%/}"`


# convert the dicoms directly to mif
mrconvert $dicomdir $mif


# get the diffusion directions the stupid way
tmpDir=/tmp/dcm2nii_$$
mkdir $tmpDir
dcm2nii -o ${tmpDir} -n y -g n $dicomdir


# put the bmatrix in the format that mrtrix likes. 
# it will be called according to the mif file, with a _encoding.b suffix.
bval=`ls ${tmpDir}/*.bval`
bvec=`ls ${tmpDir}/*.bvec`
cat $bvec $bval > ${tmpDir}/enc_tmp
transpose_table.sh ${tmpDir}/enc_tmp > ${tmpDir}/enc_tmp2
bmatrix=${mif%.mif}_encoding.b
awk '{printf "%1.6f\t%1.6f\t%1.6f\t%d\n",$1,$2,$3,$4}' ${tmpDir}/enc_tmp2 > $bmatrix


# flip gradients if necessary
inb_flip_gradients_mrtrix.sh $bmatrix ${tmpDir}/enc_tmp3 $flipOptions
cp -f ${tmpDir}/enc_tmp3 $bmatrix


# show result
mrinfo $mif


# clean up
rm -fR $tmpDir

