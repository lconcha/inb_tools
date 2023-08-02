#!/bin/bash

echo "[INFO] CUDA 9.1 is not needed for fsl 6.0.7 and above."
echo "[INFO] Not setting up CUDA 9.1, use CUDA 10.1 instead."
echo "[INFO] If you _really_ need CUDA9.1, do:"
echo "       cudaLib=/usr/local/cuda-9.1/lib64"
echo "       export LD_LIBRARY_PATH=${cudaLib}:${LD_LIBRARY_PATH}"
exit 0


cudaLib=/usr/local/cuda-9.1/lib64

if [ ! -d ${cudaLib} ]
then
  echolor red "[ERROR] Could not find $cudaLib"
  echolor red "        Cuda 9.1 has not been configured. Bye."
  exit 2
fi

export LD_LIBRARY_PATH=${cudaLib}:${LD_LIBRARY_PATH}
echolor green "[INFO] Cuda 9.1 libraries have been loaded successfully."
