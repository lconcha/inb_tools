#!/bin/bash
source `which my_do_cmd`

print_help()
{
  echo "
  `basename $0` <seeds.nii[.gz]> <tracks.tck> <pico>

  
  Luis Concha
  INB, UNAM
  October, 2012.			
"
}


if [ $# -lt 3 ] 
then
  echo " ERROR: Need more arguments..."
  print_help
  exit 1
fi



declare -i i
i=1
skip=1
for arg in "$@"
do
  case "$arg" in
    -h|-help) 
      print_help
      exit 1
    esac
    i=$[$i+1]
done


seeds=$1
tracks=$2
pico=$3



tmpDir=/tmp/pico_`random_string`
mkdir $tmpDir



my_do_cmd inb_split_seeds.sh $seeds ${tmpDir}/seeds
filtered_track=${tmpDir}/filtered_track.tck
ls ${tmpDir}/seeds*.nii | while read seed
do
  filter_tracks -quiet -include $seed $tracks $filtered_track
  tracks2prob -quiet -fraction -template $seeds $filtered_track ${seed%.nii}_p.nii
done
my_do_cmd fslmerge -t ${tmpDir}/merged_p  ${tmpDir}/seeds*_p.nii
my_do_cmd fslmaths ${tmpDir}/merged_p -Tmean ${pico}_mean
my_do_cmd fslmaths ${tmpDir}/merged_p -Tmax ${pico}_max



rm -fR $tmpDir