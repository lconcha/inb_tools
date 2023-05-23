#!/bin/bash
source `which my_do_cmd`

vec=$1
mag=$2

fakeflag=""



tmpDir=/tmp/vec2mag$$

mkdir $tmpDir
	
export FSLOUTPUTTYPE=NIFTI

my_do_cmd $fakeflag fslroi $vec ${tmpDir}/0.nii 0 1
my_do_cmd $fakeflag fslroi $vec ${tmpDir}/1.nii 1 1
my_do_cmd $fakeflag fslroi $vec ${tmpDir}/2.nii 2 1

my_do_cmd $fakeflag fslmaths ${tmpDir}/0.nii -sqr ${tmpDir}/0sq.nii
my_do_cmd $fakeflag fslmaths ${tmpDir}/1.nii -sqr ${tmpDir}/1sq.nii
my_do_cmd $fakeflag fslmaths ${tmpDir}/2.nii -sqr ${tmpDir}/2sq.nii

my_do_cmd $fakeflag fslmaths ${tmpDir}/0sq.nii -add ${tmpDir}/1sq.nii -add ${tmpDir}/2sq.nii ${tmpDir}/SS.nii

my_do_cmd $fakeflag fslmaths ${tmpDir}/SS.nii -sqrt $mag

rm -fR $tmpDir
