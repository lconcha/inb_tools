#!/bin/bash

dwi=$1; #mif
mask=$2
dwi_fixed=$3

tmpDir=$(mktemp -d -p .)


avb0=${tmpDir}/av_b0.mif
bzeros=${tmpDir}/bzeros.mif
dwi_only=${tmpDir}/dwi_only.mif
dwiextract -bzero    $dwi         - | mrcalc - $mask -mul $bzeros
dwiextract -no_bzero $dwi         - | mrcalc - $mask -mul $dwi_only
mrmath     -axis 3   $bzeros mean - | mrcalc - $mask -mul $avb0


mrcalc $dwi_only                $avb0     -gt ${tmpDir}/badvoxels.mif
mrcalc ${tmpDir}/badvoxels.mif  0         -eq  ${tmpDir}/goodvoxels.mif
mrcalc ${tmpDir}/badvoxels.mif  $avb0     -mul ${tmpDir}/badvoxels_with_b0signal.mif
mrcalc ${tmpDir}/goodvoxels.mif $dwi_only -mul ${tmpDir}/goodvoxels_with_origsignal.mif
mrcalc ${tmpDir}/badvoxels_with_b0signal.mif \
       ${tmpDir}/goodvoxels_with_origsignal.mif \
       -add \
       ${tmpDir}/dwi_only_fixed.mif
  
mrcat $bzeros ${tmpDir}/dwi_only_fixed.mif $dwi_fixed



rm -fR $tmpDir