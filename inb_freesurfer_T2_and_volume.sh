#!/bin/bash

source `which my_do_cmd`


##########################
subject=$1
##########################

print_help() {
echo 
echo "
  `basename $0` <subject>

  Note: The file \${subject}/T2/T2map.nii.gz must exist.

      Luis Concha. INB, UNAM
      March, 2013"
}




if [ $# -lt 1 ] 
then
	echo " ERROR: Need more arguments..."
	print_help
	exit 1
fi

for arg in "$@"
do
  case "$arg" in
    -h|-help) 
      print_help
      exit 1
    ;;
  esac
  index=$[$index+1]
done





# Check that the T2 map exists within the subject's directory
T2map=${SUBJECTS_DIR}/${subject}/T2/T2map.nii.gz
if [ ! -f $T2map ]
then
  echo "FATAL ERROR: $T2map does not exist"
  exit 2
else
  echo "OK: Found $T2map"
fi


# Find out if we have a FLAIR or T2 volume
flair=${SUBJECTS_DIR}/${subject}/T2/flair.nii.gz
T2=${SUBJECTS_DIR}/${subject}/T2/T2.nii.gz

if [ -f $flair ]
then
  ref=$flair
  cost_function=normmi
elif [ -f $T2 ]
then
  ref=$T2
  cost_function=corratio
else
  echo "FATAL ERROR: Cannot find either a flair or T2 image!"
  exit 2
fi

echo "INFO: Reference image is: $ref"

xfm_t2map_to_anat=${SUBJECTS_DIR}/${subject}/T2/T2map_to_anat.mat
if [ -f $xfm_t2map_to_anat ]
then
  echo "INFO: xfm already computed: $xfm_t2map_to_anat"
else
  my_do_cmd flirt \
    -in $T2map \
    -ref $ref \
    -omat $xfm_t2map_to_anat \
    -dof 6 \
    -cost $cost_function \
    -nosearch
fi

# Let's remove the CSF from the T2 map by using a high threshold. Tissue should be <150 ms, but let's be safe:
T2map_masked=${SUBJECTS_DIR}/${subject}/T2/T2map_noCSF.nii.gz
CSF_T2_threshold=250
my_do_cmd fslmaths \
  $T2map \
  -uthr $CSF_T2_threshold \
  -bin \
  -mul $T2map \
  $T2map_masked
  

# And apply the transformation matrix to that masked T2 map to go to FLAIR (or T2) space:
T2map_to_anat=${SUBJECTS_DIR}/${subject}/T2/T2map_to_anat.nii.gz
my_do_cmd flirt \
  -in $T2map_masked \
  -ref $ref \
  -applyxfm -init $xfm_t2map_to_anat \
  -out $T2map_to_anat


# Now we get freesurfer's T1, and register or T2/FLAIR to it
T1nifti=${SUBJECTS_DIR}/${subject}/T2/tmp_t1.nii
my_do_cmd mri_convert \
  ${SUBJECTS_DIR}/${subject}/mri/T1.mgz \
  $T1nifti


xfm_anat_to_T1=${SUBJECTS_DIR}/${subject}/T2/anat_to_T1.mat
if [ -f $xfm_anat_to_T1 ]
then
  echo "INFO: xfm already computed: $xfm_anat_to_T1"
else
  my_do_cmd flirt \
    -in $ref \
    -ref $T1nifti \
    -omat $xfm_anat_to_T1
fi

xfm_T2map_to_T1=${SUBJECTS_DIR}/${subject}/T2/T2map_to_T1.mat
xfm_T1_to_T2map=${SUBJECTS_DIR}/${subject}/T2/T1_to_T2map.mat
my_do_cmd convert_xfm \
 -omat $xfm_T2map_to_T1 \
 -concat $xfm_anat_to_T1 $xfm_t2map_to_anat

my_do_cmd convert_xfm \
 -omat $xfm_T1_to_T2map \
 -inverse $xfm_T2map_to_T1 

T2map_to_T1=${SUBJECTS_DIR}/${subject}/T2/T2map_to_T1.nii.gz
my_do_cmd flirt \
  -in $T2map_masked \
  -ref $T1nifti \
  -applyxfm -init $xfm_T2map_to_T1 \
  -out $T2map_to_T1

T1_to_T2map=${SUBJECTS_DIR}/${subject}/T2/T1_to_T2map.nii.gz
my_do_cmd flirt \
 -in $T1nifti \
 -ref $T2map \
 -applyxfm -init $xfm_T1_to_T2map \
 -out $T1_to_T2map


# Now we get the T2 values from the subcortical automatic segmentation
aseg_nifti=${SUBJECTS_DIR}/${subject}/T2/tmp_aseg.nii
my_do_cmd mri_convert ${SUBJECTS_DIR}/${subject}/mri/aseg.mgz $aseg_nifti
aseg_to_T2map=${SUBJECTS_DIR}/${subject}/T2/tmp_aseg_to_T2map.nii.gz
my_do_cmd flirt \
 -in $aseg_nifti \
 -ref $T2map \
 -applyxfm -init $xfm_T1_to_T2map \
 -interp nearestneighbour \
 -out $aseg_to_T2map



mask=${SUBJECTS_DIR}/${subject}/T2/tmp_T2_mask.nii.gz
# (the mask makes sure we are not sampling CSF spaces that were mis-registered with respect to the automatic segmentation)
# (this way, atrophic hippocampi will not have long T2 values just due to CSF contamination)
my_do_cmd fslmaths $T2map_masked -bin $mask
my_do_cmd mri_segstats \
  --seg $aseg_to_T2map \
  --ctab $FREESURFER_HOME/FreeSurferColorLUT.txt \
  --nonempty \
  --excludeid 0 \
  --sum ${SUBJECTS_DIR}/${subject}/T2/stats_T2.txt \
  --in $T2map_masked \
  --mask $mask


# Make a summary for the hippocampus
stats_t1_file=${SUBJECTS_DIR}/${subject}/stats/aseg.stats
stats_t2_file=${SUBJECTS_DIR}/${subject}/T2/stats_T2.txt

hippo_L_vol=`grep Left-Hippocampus $stats_t1_file | awk '{print $4}'`
hippo_R_vol=`grep Right-Hippocampus $stats_t1_file | awk '{print $4}'`
hippo_L_T2=`grep Left-Hippocampus $stats_t2_file | awk '{print $6}'`
hippo_R_T2=`grep Right-Hippocampus $stats_t2_file | awk '{print $6}'`

echo "
---------------------------------
Summary of hippocampi
" | tee -a ${SUBJECTS_DIR}/${subject}/T2/hippocampus.txt
printf "%s\t%s\t%s\n" Volume Left Right | tee -a ${SUBJECTS_DIR}/${subject}/T2/hippocampus.txt
printf "  \t%1.1f\t%1.1f\n" $hippo_L_vol $hippo_R_vol | tee -a ${SUBJECTS_DIR}/${subject}/T2/hippocampus.txt
echo "" | tee -a ${SUBJECTS_DIR}/${subject}/T2/hippocampus.txt
printf "%s\t%s\t%s\n" "T2(ms)" Left Right | tee -a ${SUBJECTS_DIR}/${subject}/T2/hippocampus.txt
printf "  \t%1.1f\t%1.1f\n" $hippo_L_T2 $hippo_R_T2 | tee -a ${SUBJECTS_DIR}/${subject}/T2/hippocampus.txt




rm -f ${SUBJECTS_DIR}/${subject}/T2/tmp_*