#!/bin/bash


PDDs=$1
METRIC=$2; # usually COMP_SIZE, but it can also be FA or MD.
scaled_PDDs=$3

tmpDir=$(mktemp -d)


epsilon=0.000001; # to make sure we always have a fixel even when the metric to scale by is zero.


nComponents=$(mrinfo -size $METRIC | awk '{print $4}')
echolor green "[INFO] Max number of components per voxel is $nComponents"

for c in $(seq 0 $(($nComponents -1)))
do
  i=$(mrcalc $c 2 -mul $c -add)
  j=$(mrcalc $i 2 -add)
  echolor green "[INFO] Tensor $c, volumes $i to $j"
  mrconvert -quiet -coord 3 $i:$j $PDDs ${tmpDir}/PDD_${c}.mif
  mrconvert -quiet -coord 3 $c $METRIC ${tmpDir}/fraction_${c}.mif
  mrcalc -quiet ${tmpDir}/PDD_${c}.mif \
    ${tmpDir}/fraction_${c}.mif \
    -mul \
    $epsilon -add \
    ${tmpDir}/scaled_PDD_${c}.mif
done



mrcat -quiet -axis 3 ${tmpDir}/scaled_PDD_*.mif $scaled_PDDs

rm -fR $tmpDir