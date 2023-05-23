#!/bin/bash

hostname
date

eddynotfound=`eddy_cuda9.1 2>&1 | grep "command not found"`
nocuda=`eddy_cuda9.1 2>&1 | grep "error while loading shared libraries"`
isOK=`eddy_cuda9.1 2>&1 | grep "Oxford"`

if [ ! -z "$eddynotfound" ]
then
  echo "ERROR. eddy_cuda9.1 not found in PATH."
  echo $notfound
  echo "  try typing: fsl602"
  exit 2
fi

if [ ! -z "$nocuda" ]
then
  echo "ERROR. Cuda not found."
  echo $notfound
  echo "  try typing: source /home/inb/lconcha/fmrilab_software/tools/inb_config_cuda9.sh"
  exit 2
fi

if [ ! -z "${isOK}" ]
then
  echo "INFO: eddy_cuda9.1 seems to work!"
fi


