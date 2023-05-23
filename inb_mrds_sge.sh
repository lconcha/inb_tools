#!/bin/bash

#!/bin/bash
source `which my_do_cmd`

help(){
  echo "


Fit multi-tensors using multi-resolution discrete search (MRDS) within a mask.



How to use:
  `basename $0` <dwi> <bvec> <bval> <mask> <outbase> <n_voxels_per_job> <scratch_dir>

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


if [ $# -lt 5 ]
then
  echolor red "Not enough arguments"
	help
  exit 2
fi




dwi=$1
bvec=$2
bval=$3
mask=$4
outbase=$5
n_voxels_per_job=$6
scratch_dir=$7

echolor yellow "
  dwi                       : $dwi
  bvec                      : $bvec
  bval                      : $bval
  mask                      : $mask
  outbase                   : $outbase
  n_voxels_per_job          : $n_voxels_per_job
  scratch_dir               : $scratch_dir
"

tmpDir=`mktemp -d -p $scratch_dir`


cat $bvec $bval > ${tmpDir}/bvalbvec
transpose_table.sh ${tmpDir}/bvalbvec > ${tmpDir}/schemeorig
awk '{printf "%.5f %.5f %.5f %.4f\n", $1,$2,$3,$4}' ${tmpDir}/schemeorig > ${outbase}.scheme
scheme=${outbase}.scheme


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
echolor yellow "  $response"


my_do_cmd masksplit.sh $mask $n_voxels_per_job ${tmpDir}/mask4D.nii

nVolsROI=$(mrinfo -size ${tmpDir}/mask4D.nii | awk '{print $4}')
echo "nVolsROI is $nVolsROI"


list_mrds_jobs=${tmpDir}/mrds_job_array
for frame in $(seq 0 $(($nVolsROI -1)))
do
    thismask=${tmpDir}/mask_${frame}.nii
    my_do_cmd mrconvert -coord 3 $frame ${tmpDir}/mask4D.nii $thismask
   
    echo "mdtmrds \
    $dwi \
    $scheme \
    ${tmpDir}/mrds_job_${frame} \
    -correction 0 \
    -response $response \
    -mask $thismask \
    -modsel all \
    -each \
    -intermediate \
    -fa -md -mse \
    -method diff 1" >> $list_mrds_jobs
done

nVols=`wc -l $list_mrds_jobs`
echolor reverse "  Submitting $nVols mrds jobs"
jidPar=`fsl_sub -s smp,4 -N mrdsPar -t $list_mrds_jobs -l $tmpDir`
echolor cyan "[INFO] Job ID for array of mrds jobs: $jidPar"


#ls $tmpDir
#rm -fR $tmpDir
