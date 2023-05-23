#!/bin/bash
source `which my_do_cmd`




# Help function
function help() {
		echo "
		Compute a T2 map in nifti format.
		

		use:
		`basename $0` raw_t2_images_4D.nii.gz t2map.nii.gz echoes.txt mask.nii.gz
    

		"
		exit 1
}

export FSLOUTPUTTYPE=NIFTI

raw=$1
t2map=$2
echoes=$3
mask=$4

fakeFlag=""

tmpDir=./tmp_$$
mkdir $tmpDir


jobfile_pre=${tmpDir}/jobfile_pre.txt
fslsplit $raw  $tmpDir/im_   -z
fslsplit $mask $tmpDir/mask_ -z


# Create a job array
jobfile_slices=${tmpDir}/slices_t2map_job.txt 
for f in $tmpDir/im_*.nii
do
  echo "inb_t2map.sh $f ${f/im/t2map} $echoes ${f/im/mask}" >> $jobfile_slices
done
id_slices=`fsl_sub -t $jobfile_slices`

jobfile_post=${tmpDir}/jobfile_post.txt
echo "fslmerge -z $t2map $tmpDir/t2map_*.nii" >> $jobfile_post
echo "#rm -fR $tmpDir" >> $jobfile_post
fsl_sub -j $id_slices -t $jobfile_post




