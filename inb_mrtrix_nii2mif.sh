#!/bin/bash

nii=$1
mif=$2
bvec=$3
bval=$4

keeptmp=0


print_help()
{
  echo "
  `basename $0` <dti.nii.gz> <dti.mif> <bvec> <bval>[-Options]

  Options:
  
  -notDTI
  -flip_x
  -flip_y
  -flip_z
  -clobber
  -onlyGrads

  Luis Concha
  INB
  Feb 2011			
"
}

isDTI=1
if [ $# -lt 2 ] 
then
  echo "  ERROR: Need more arguments..."
  print_help
  exit 1
fi

if [ $# -lt 4 ] 
then
  echo "  This is not a DTI file (or gradient info was not provided)"
  isDTI=0
fi



flipOptions=""
clobber=0
onlyGrads=0
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
	   -clobber)
		clobber=1
		;;
	   -notDTI)
		isDTI=0
		;;
	   -keeptmp)
		keeptmp=1
		;;
	   -onlyGrads)
		onlyGrads=1
		;;
	esac
	index=$[$index+1]
done




if [ -f $mif ]
then
  if [ $clobber -eq 0 ]
  then
    echo "  File $mif exists. Use -clobber to overwrite. Quitting".
    exit 1
  else
    echo  "  File $mif exists. WILL OVERWRITE ORIGINAL".
    rm -f $mif
  fi
fi


# create a tmp directory
tmpDir=/tmp/nii2mif_$$
mkdir $tmpDir




gz=0
if [ -n "`echo ${nii} | grep .gz`" -a $onlyGrads -eq 0 ]
then
   echo "  File is zipped. Unzipping..."
   gunzip -v $nii
   nii=${nii%.gz}
   gz=1
fi




# convert to mif
if [ $onlyGrads -eq 0 ]
then
  mrconvert $nii $mif
fi


if [ $isDTI -eq 1 ]
then
  # put the bmatrix in the format that mrtrix likes. 
  # it will be called according to the mif file, with a _encoding.b suffix.
  echo "  Obtaining diffusion direction information... "
  sed '/^$/d' $bvec  > ${tmpDir}/enc_tmp
  sed '/^$/d' $bval  >> ${tmpDir}/enc_tmp
  transpose_table.sh ${tmpDir}/enc_tmp > ${tmpDir}/enc_tmp2
  bmatrix=${mif%.mif}_encoding.b
  awk '{printf "%1.6f\t%1.6f\t%1.6f\t%d\n",$1,$2,$3,$4}' ${tmpDir}/enc_tmp2 > $bmatrix


  # flip gradients if necessary
  echo "  Finishing up the gradient directions ..."
  inb_flip_gradients_mrtrix.sh $bmatrix ${tmpDir}/enc_tmp3 $flipOptions
  cp -f ${tmpDir}/enc_tmp3 $bmatrix
fi

# clean up
if [ $keeptmp -eq 0 ]
then
  rm -fR $tmpDir
else
  echo "Keeping tmpdir: $tmpDir"
fi	


# gzip again
if [ $gz -eq 1 ]
then
  echo "  zipping back the nii..."
  gzip -v $nii
fi

echo "  Done."