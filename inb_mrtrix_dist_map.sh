#!/bin/bash



print_help()
{
echo "
`basename $0` <track.tck> <ref.nii> <seed.nii> <output_dist_map.nii>

 Luis Concha
 INB, October 2012.

"
}



if [ $# -lt 4 ] 
then
	echo " ERROR: Need more arguments..."
	print_help
	exit 1
fi







track=$1
ref=$2
seed=$3
dist_map=$4


OK=1
for f in $track $seed $ref
do
  if [ ! -f $f ]
  then
      echo "ERROR: $f does not exist"
      OK=0
  else
      echo "OK, found $f"
  fi
done
if [ $OK -eq 0 ]
then
  exit 2
fi


echo "OCTAVE: octave --eval [track2, dist_vol] = track_length('$track','$ref','$seed','$dist_map');"
octave --eval "[track2, dist_vol] = track_length('$track','$ref','$seed','$dist_map');"

#matlab -nodisplay <<EOF
#[track2, dist_vol] = track_length('$track','$ref','$seed','$dist_map');
#EOF