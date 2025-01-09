#!/bin/bash
source `which my_do_cmd`

help() {
  echo "
  `basename $0` [options] PDDs METRIC out_scaled_PDDs


  PDDs            A 4D file that has the cartesian Principal Diffusion Directions for each
                  tensor found within each voxel. The size in the 4th dimension has to be
                  a multiple of 3, with data stored as x1,y1,z1,x2,y2,z2,...xn,yn,zn.
                  These vectors are normalized (magnitude=1).
  METRIC          A 3D file with a scalar per voxel that will be used to scale the PDD.
                  Typically this is the compartment size for each fixel, but it can be FA, MD, etc (per fixel).
                  Data should be ordered as v1,v2,...vn. (one scalar, v, per fixel).
  out_scaled_PDDs Output file. It has the same dimensions and ordering as PDDs
                  These vectors are scaled by METRIC, and thus their magnitude is not equal to 1.
 

  Options:

  -e float   A very small number to add if a fixel exists but METRIC is zero.
             If not used, there is a risk that fixels are lost when scaled by zero.
             Not used by default as to avoid messing with your data, but if used, a good value is 0.000001.

  -h         Print this, duh.



  LU15 (0N(H4
  INB-UNAM
  Jan 2025
  lconcha@unam.mx
  "
}


if [ $# -lt 3 ]
then
  echolor red "ERROR: Need three arguments"
	help
  exit 2
fi


epsilon=0.0; # increase to something like 0.000001 to make sure we always have a fixel even when the metric to scale by is zero.
while getopts he: flag
do
    case "${flag}" in
        e) epsilon=${OPTARG}
           echo "  Option: Epsilon=$epsilon"
           shift
           shift
           ;;
        h) help;exit 2;;
    esac
done


PDDs=$1
METRIC=$2; # usually COMP_SIZE, but it can also be FA or MD.
scaled_PDDs=$3


tmpDir=$(mktemp -d)

nComponents=$(mrinfo -size $METRIC | awk '{print $4}')
echolor green "[INFO] Max number of components per voxel is $nComponents"

for c in $(seq 0 $(($nComponents -1)))
do
  i=$(mrcalc $c 2 -mul $c -add)
  j=$(mrcalc $i 2 -add)
  echolor green "[INFO] Tensor $c, volumes $i to $j"
  mrconvert -quiet -coord 3 $i:$j $PDDs ${tmpDir}/PDD_${c}.mif
  mrconvert -quiet -coord 3 $c $METRIC ${tmpDir}/metric_${c}.mif
  mrcalc ${tmpDir}/PDD_${c}.mif -abs 0 -gt - | mrmath -axis 3 - max - | mrcalc - $epsilon -mul ${tmpDir}/epsilon_${c}.mif
  #mrcalc ${tmpDir}/metric_${c}.mif -abs 0 -gt ${tmpDir}/hasvalue_${c}.mif

  mrcalc -quiet ${tmpDir}/PDD_${c}.mif \
    ${tmpDir}/metric_${c}.mif \
    -mul \
    ${tmpDir}/epsilon_${c}.mif -add \
    ${tmpDir}/scaled_PDD_${c}.mif
done



my_do_cmd mrcat -quiet -axis 3 ${tmpDir}/scaled_PDD_*.mif $scaled_PDDs

rm -fR $tmpDir
