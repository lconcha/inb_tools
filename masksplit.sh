#!/bin/bash
source `which my_do_cmd`

function help(){
echo "
`basename $0` <roi3D> <nVoxels> <roi4D>

Turn a 3D mask (ROI) that includes several voxels into a series of
smaller ROIs (each with nVoxels), concatenated in the fourth dimension.

Useful for submitting parallel jobs.


LU15 (0N(H4
INB-UNAM
May 2023
lconcha@unam.mx
"
}


if [ $# -lt 3 ]
then
	echo " ERROR: Need more arguments..."
	help
	exit 2
fi


mask=$1
nvoxels=$2
mask4D=$3



tmpDir=$(mktemp -d)

mrcalc -quiet -datatype bit $mask 0 -gt - | \
maskdump - > ${tmpDir}/voxels.txt
nOnesInMask=$(wc -l ${tmpDir}/voxels.txt | awk '{print $1}')
echo "There are $nOnesInMask voxels in $mask"

split -l $nvoxels ${tmpDir}/voxels.txt ${tmpDir}/splitvoxels_
nVolumes=$(ls ${tmpDir}/splitvoxels_* | wc -l)
echo "Split into $nVolumes volumes, each with $nvoxels voxels."

n=0
for f in ${tmpDir}/splitvoxels_*
do
  n=$(( $n +1 ))
  
  mrcalc -quiet  $mask 0 -mul ${f}.mif
  
  voxelsToEdit=" "
  while read v
  do
    vv=${v// /,}
    voxelsToEdit="$voxelsToEdit -voxel $vv 1 "
  done < <(cat $f)
  

  mredit $voxelsToEdit ${f}.mif 
  
done

mrcat -quiet -axis 3 ${tmpDir}/splitvoxels_*.mif $mask4D


rm -fR $tmpDir
echo "Done."