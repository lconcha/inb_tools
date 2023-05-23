#!/bin/bash


inDIR=$1
niftisDIR=/tmp/niftis_$$
outDir=$2

dcm2nii -g n -f y -r n -t y -v y -x n -o $niftisDir $inDir


slicesdir $niftisDIR



rm -fR $niftisDir