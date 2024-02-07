#!/bin/bash
source `which my_do_cmd`

#export SUBJECTS_DIR=/misc/mansfield/lconcha/exp/glaucoma/fs_glaucoma
sID=$1


help(){
  echo "


Fit multi-tensors using multi-resolution discrete search (MRDS).
Assumes files are organized in freesurfer-style fashion.

This takes a long, long time (days). Submit to queue by prepending fsl_sub

Uses multi-threading, avoid running multiple jobs at the same time.


How to use:
  `basename $0` <sID>

  Please note that SUBJECTS_DIR must be set as environment variable.

  SID = subject ID, the name of the subject in freesurfer fashion, and expects to find:

    dwi     = \${SUBJECTS_DIR}/\${sID}/dwi/dwi.nii.gz
    scheme  = \${SUBJECTS_DIR}/\${sID}/dwi/dwi.scheme
    mask    = \${SUBJECTS_DIR}/\${sID}/dwi/mask.nii.gz
    


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


if [ $# -lt 1 ]
then
  echolor red "Not enough arguments"
	help
  exit 2
fi


dwi=${SUBJECTS_DIR}/${sID}/dwi/dwi.nii.gz
bvec=${SUBJECTS_DIR}/${sID}/dwi/dwi.bvec
bval=${SUBJECTS_DIR}/${sID}/dwi/dwi.bval
scheme=${SUBJECTS_DIR}/${sID}/dwi/dwi.scheme
mask=${SUBJECTS_DIR}/${sID}/dwi/mask.nii.gz
outdir=${SUBJECTS_DIR}/${sID}/dwi/
logfile=${SUBJECTS_DIR}/${sID}/scripts/mrds.log

isOK=1
for f in $dwi $scheme $mask
do
  if [ -f "$f" ]
  then
    echolor green "[INFO] Found $f"
  else
    echolor red "[ERROR] File not found: $f"
    isOK=0
  fi
done
if [ $isOK -eq 0 ]; then exit 2; fi


if [ -f $logfile ]; then rm $logfile;fi

echo "Computing MRDS..." > $logfile
date >> $logfile
echo $@ >> $logfile

local_tmpDir=/tmp/mrds_$(whoami)_${RANDOM}
mkdir -pv $local_tmpDir

my_do_cmd cp $dwi $bvec $bval $scheme $mask ${local_tmpDir}/
dwi=${local_tmpDir}/dwi.nii.gz
bvec=${local_tmpDir}/dwi.bvec
bval=${local_tmpDir}/dwi.bval
scheme=${local_tmpDir}/dwi.scheme
mask=${local_tmpDir}/mask.nii.gz


my_do_cmd dti \
  -mask $mask \
  -response 0 \
  -correction 0 \
  -fa -md \
  $dwi \
  $scheme \
  ${local_tmpDir}/${sID}


response=$( cat ${local_tmpDir}/${sID}_DTInolin_ResponseAnisotropic.txt | awk '{OFS = "," ;print $1,$2}' )


my_do_cmd mdtmrds \
  $dwi \
  $scheme \
  ${local_tmpDir}/${sID} \
  -correction 0 \
  -response $response \
  -mask $mask \
  -modsel bic \
  -fa -md -mse \
  -method diff 1


my_do_cmd gzip ${local_tmpDir}/*.nii
rsync -av ${local_tmpDir}/${sID}*.nii.gz ${outdir}/
rm -fRv ${local_tmpDir}

date >> $logfile
