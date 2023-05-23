#!/bin/bash

cudaLib=/usr/local/cuda-9.1/lib64

if [ ! -d ${cudaLib} ]
then
  echolor red "[ERROR] Could not find $cudaLib"
  echolor red "        Cuda 9.1 has not been configured. Bye."
  exit 2
fi

export LD_LIBRARY_PATH=${cudaLib}:${LD_LIBRARY_PATH}
echolor green "[INFO] Cuda 9.1 libraries have been loaded successfully."
