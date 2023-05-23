#!/bin/bash
source `which my_do_cmd`

surf_orig=$1
coords_warped=$2
surf_warped=$3


tmpDir=/tmp/surf_modify_coords_`random_string`
mkdir -p $tmpDir
tmpbase=${tmpDir}/tmp

surf_orig_ascii=${tmpbase}_ascii.asc
my_do_cmd mris_convert $surf_orig $surf_orig_ascii

nVertices=`head -n 2 $surf_orig_ascii | tail -n 1 | awk '{print $1}'`
nFaces=`head -n 2 $surf_orig_ascii | tail -n 1 | awk '{print $2}'`

nCoords=`wc -l $coords_warped | awk '{print $1}'`

echo "Surface has $nVertices vertices and $nFaces faces."
echo "There are $nCoords coordinates"

if [ $nVertices -ne $nCoords ]
then
  echo "ERROR: Incompatible number of vertices and coords."
  exit 2
fi


head -n 2 $surf_orig_ascii > $surf_warped
echo "  Modifying coordinates according to $coords_warped"
awk '{print $1,$2,$3,0}' $coords_warped >> $surf_warped


#echo "tail -n $nFaces $surf_orig_ascii >> $surf_warped"
tail -n $nFaces $surf_orig_ascii >> $surf_warped
echo "  Done writing $surf_warped."

rm -fR $tmpDir