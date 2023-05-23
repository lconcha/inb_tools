#!/bin/bash
source `which my_do_cmd`

# http://andysbrainblog.blogspot.com/2013/04/fsl-tutorial-creating-rois-from.html

im=$1
x=$2
y=$3
z=$4
radius=$5
out=$6
# coords should be in voxel coords, not mm




tmpDir=/tmp/sphere_$$
mkdir $tmpDir

my_do_cmd fslmaths $im \
  -mul 0 \
  -add 1 \
  -roi $x 1 $y 1 $z 1 0 1 \
  ${tmpDir}/point \
  -odt float

my_do_cmd fslmaths ${tmpDir}/point \
  -kernel sphere $radius \
  -fmean \
  ${tmpDir}/sphere \
  -odt float

my_do_cmd fslmaths ${tmpDir}/sphere \
  -bin \
  $out


rm -fR $tmpDir
