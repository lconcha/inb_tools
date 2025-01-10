#!/bin/bash
source `which my_do_cmd`

help(){
  echo "


Fit multi-tensors using multi-resolution discrete search (MRDS) within a mask.

Please allow around one hour per slice analyzed.
Uses multi-threading, avoid running multiple jobs at the same time.


How to use:
  `basename $0` <dwi> <scheme> <mask> <outbase>

Provide all image files as .nii or .nii.gz (dwi and mask).

Note:    MRDS cannot handle DWI data sets without b=0 volumes. 
         The Bruker scanner provides bvals that include diffusion gradient sensitization
         from all gradients, including the spatial encoding gradients and crushers, and
         therefore there are no b=0 bvals, but rather a very small b value (e.g b=28 s/mm2).
         This script will automatically find the lowest bvalue and turn it to zero.

Warning: If you did not acquire b=0 volumes, then don't use this script!


This script wraps the MRDS functions by Ricardo Coronado.To cite:
Coronado-Leija, Ricardo, Alonso Ramirez-Manzanares, and Jose Luis Marroquin. 
  Estimation of individual axon bundle properties by a Multi-Resolution Discrete-Search method.
  Medical Image Analysis 42 (2017): 26-43.
  doi.org/10.1016/j.media.2017.06.008



LU15 (0N(H4
INB UNAM
Feb 2022
lconcha@unam.mx
  "
}


if [ $# -lt 4 ]
then
  echolor red "Not enough arguments"
	help
  exit 2
fi


response=""
while getopts "r:" options
do
  case $options in
    r)
      response_file=${OPTARG}
      if [ ! -f $response ]; then 
        echo "Error: File does not exist: $response "
        exit 2
      fi
      response=$(cat $response_file | awk '{OFS = "," ;print $1,$2}')
      echolor green "[INFO] Response provided is $response"
      shift;shift
    ;;
    :)
      echo "Error: -${OPTARG} requires an argument."
      exit 2
    ;;
    *)
      echo "Error: Unknown option"
      exit 2
    ;;
  esac
done



dwi=$1
scheme=$2
mask=$3
outbase=$4

echolor yellow "
  dwi                       : $dwi
  scheme                    : $scheme
  mask                      : $mask
  outbase                   : $outbase
"


tmpDir=`mktemp -d`
echolor green "Created $tmpDir"

#cat $bvec $bval > ${tmpDir}/bvalbvec
#transpose_table.sh ${tmpDir}/bvalbvec > ${tmpDir}/schemeorig
#awk '{printf "%.5f %.5f %.5f %.4f\n", $1,$2,$3,$4}' ${tmpDir}/schemeorig > ${outbase}.scheme
#scheme=${outbase}.scheme

# remove non-vector lines from the scheme file (comments)
sed '/^s*#/ d' $scheme > ${tmpDir}/dwi.scheme
scheme=${tmpDir}/dwi.scheme



shells=`mrinfo -quiet -bvalue_scaling false -grad $scheme $dwi -shell_bvalues`
firstbval=`echo $shells | awk '{print $1}'`
if (( $(echo "$firstbval > 0 " | bc -l)  ))
then
  echolor orange "Lowest bvalue is not zero, but $firstbval .  Will change to zero. "
  sed -i -e "s/${firstbval}/0.0000/g" $scheme
fi


#echolor yellow "[INFO] Creating a generous mask from which we can estimate response."
#fullmask=${tmpDir}/fullmask.nii
#dwi2mask -grad $scheme $dwi $fullmask


if [ -z "$response" ]
then
  my_do_cmd dti \
    -mask $mask \
    -response 0 \
    -correction 0 \
    -fa -md \
    $dwi \
    $scheme \
    ${outbase}
  nAnisoVoxels=`fslstats ${outbase}_DTInolin_ResponseAnisotropicMask.nii -V | awk '{print $1}'`
  if [ $nAnisoVoxels -lt 1 ]
  then
    echolor red "[ERROR] Not enough anisotropic voxels found for estimation of response. Found $nAnisoVoxels"
  fi
  echolor yellow "Getting lambdas for response (from $nAnisoVoxels voxels)"
  response=`cat ${outbase}_DTInolin_ResponseAnisotropic.txt | awk '{OFS = "," ;print $1,$2}'`
fi

echolor yellow "Response:  $response"


my_do_cmd mdtmrds \
  $dwi \
  $scheme \
  ${outbase} \
  -correction 0 \
  -response "$response" \
  -mask $mask \
  -modsel all \
  -each \
  -intermediate \
  -fa -md -mse \
  -method diff 1


#rm -fR $tmpDir
ls $tmpDir