#!/bin/bash


PDDs=$1
COMPSIZES=$2
scaled_PDDs=$3

tmpDir=$(mktemp -d)

# mrconvert -quiet -coord 3 0:2 $PDDs ${tmpDir}/PDD_0.mif
# mrconvert -quiet -coord 3 3:5 $PDDs ${tmpDir}/PDD_1.mif
# mrconvert -quiet -coord 3 6:8 $PDDs ${tmpDir}/PDD_2.mif


nComponents=$(mrinfo -size $COMPSIZES | awk '{print $4}')
echolor green "[INFO] Max number of components per voxel is $nComponents"

for c in $(seq 0 $(($nComponents -1)))
do
  i=$(mrcalc $c 2 -mul $c -add)
  j=$(mrcalc $i 2 -add)
  echolor green "[INFO] Tensor $c, volumes $i to $j"
  mrconvert -quiet -coord 3 $i:$j $PDDs ${tmpDir}/PDD_${c}.mif
  mrconvert -quiet -coord 3 $c $COMPSIZES ${tmpDir}/fraction_${c}.mif
  mrcalc -quiet ${tmpDir}/PDD_${c}.mif \
    ${tmpDir}/fraction_${c}.mif \
    -mul \
    ${tmpDir}/scaled_PDD_${c}.mif
done


# mrconvert -quiet -coord 3 0 $COMPSIZES ${tmpDir}/fraction_0.mif
# mrconvert -quiet -coord 3 1 $COMPSIZES ${tmpDir}/fraction_1.mif
# mrconvert -quiet -coord 3 2 $COMPSIZES ${tmpDir}/fraction_2.mif

# mrcalc ${tmpDir}/PDD_0.mif ${tmpDir}/fraction_0.mif -mul ${tmpDir}/scaled_PDD_0.mif
# mrcalc ${tmpDir}/PDD_1.mif ${tmpDir}/fraction_1.mif -mul ${tmpDir}/scaled_PDD_1.mif
# mrcalc ${tmpDir}/PDD_2.mif ${tmpDir}/fraction_2.mif -mul ${tmpDir}/scaled_PDD_2.mif


mrcat -quiet -axis 3 ${tmpDir}/scaled_PDD_*.mif $scaled_PDDs

rm -fR $tmpDir