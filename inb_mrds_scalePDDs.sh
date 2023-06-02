#!/bin/bash


PDDs=$1
NUMCOMP=$2
scaled_PDDs=$3

tmpDir=$(mktemp -d)

mrconvert -coord 3 0:2 $PDDs ${tmpDir}/PDD_0.mif
mrconvert -coord 3 3:5 $PDDs ${tmpDir}/PDD_1.mif
mrconvert -coord 3 6:8 $PDDs ${tmpDir}/PDD_2.mif


mrinfo $NUMCOMP

mrconvert -coord 3 0 $NUMCOMP ${tmpDir}/fraction_0.mif
mrconvert -coord 3 1 $NUMCOMP ${tmpDir}/fraction_1.mif
mrconvert -coord 3 2 $NUMCOMP ${tmpDir}/fraction_2.mif

mrcalc ${tmpDir}/PDD_0.mif ${tmpDir}/fraction_0.mif -mul ${tmpDir}/scaled_PDD_0.mif
mrcalc ${tmpDir}/PDD_1.mif ${tmpDir}/fraction_1.mif -mul ${tmpDir}/scaled_PDD_1.mif
mrcalc ${tmpDir}/PDD_2.mif ${tmpDir}/fraction_2.mif -mul ${tmpDir}/scaled_PDD_2.mif


mrcat -axis 3 ${tmpDir}/scaled_PDD_{0,1,2}.mif $scaled_PDDs

rm -fR $tmpDir