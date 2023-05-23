#!/bin/bash
source `which my_do_cmd`


# Defaults:
seedsPerVoxel=2
fakeflag=""


print_help()

{
echo "
`basename $0` <pmap.nii.gz> <clusterSeed.nii.gz> <xfm.mat> <CSD.nii.gz> <mask> <tracks.tck> [-options]

All inputs are mandatory and are:

pmap.nii.gz         : The thresholded z or p map derived form a feat of the contrast of interest.
clusterSeed.nii.gz  : A binary mask of a single voxel within the pseudo-cluster of interest.
                      This is drawn in the same space as pmap.nii.gz. It will also be transformed to dti space.
xfm.mat             : The transformation needed to go from the space of the pmap to the dti space.
                      This could be either standard2b0.mat or bold2b0.mat.
                      Take a look at marc_fMRI_dti_reg.sh for this.
CSD.nii.gz          : The CSD file that mrtrix produces.
mask.nii.gz         : A binary mask of the (bet) brain.
tracks.tck          : The output tracks.


Options are:

-h or -help          : Show this message.
-fake                : Do a dry run.
-seedsPerVoxel <int> : How many seeds to plant per voxel. Default is $seedsPerVoxel .
                       Careful, as large ROIs will lead to huge numbers of tracks.
-streamtrackOptions <\"list of other options for streamtrack\"> 
                    (use streamtrack --help to see them all).


Luis Concha
INB
2012
lconcha@unam.mx
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
for arg in "$@"
do
  case "$arg" in
  -h|-help) 
    print_help
    exit 1
  ;;
  -fake)
    fakeflag="-fake"
  ;;
  -seedsPerVoxel)
    nextarg=`expr $i + 1`
    eval seedsPerVoxel=\${${nextarg}}
  ;;
  -streamtrackOptions)
    nextarg=`expr $i + 1`
    eval streamtrackOptions=\${${nextarg}}
  ;;
  esac
  i=$[$i+1]
done





tmpDir=/tmp/music_seed_`random_string`
mkdir $tmpDir


pmap=$1
clusterSeed=$2
xfm=$3
CSD=$4
mask=$5
tracks=$6




pmapTransformed=${tmpDir}/pmap_transformed.nii.gz
my_do_cmd $fakeflag flirt \
  -in $pmap \
  -out $pmapTransformed \
  -ref $mask \
  -applyxfm -init $xfm



clusterSeedTransformed=${tmpDir}/clusterSeed_transformed.nii.gz
my_do_cmd $fakeflag flirt \
  -in $clusterSeed \
  -out $clusterSeedTransformed \
  -ref $mask \
  -applyxfm -init $xfm




seed=seed.nii.gz
my_do_cmd $fakeflag inb_flood_fill.sh $pmapTransformed $clusterSeedTransformed $seed
nSeedVoxels=`fslstats $seed -V | awk '{print $1}'`
numberOfSeeds=$(($nSeedVoxels * $seedsPerVoxel))


my_do_cmd $fakeflag streamtrack $streamtrackOptions \
  -seed $seed \
  -mask $mask \
  -number $numberOfSeeds \
  SD_PROB $CSD $tracks


rm -fR $tmpDir