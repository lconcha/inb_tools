#!/bin/bash
source `which my_do_cmd`
export FSLOUTPUTTYPE=NIFTI
unset FSLPARALLEL

# prepare a 5TT from FA and ADC maps using FAST and FIRST



# Positional arguments
fa=$1
adc=$2
out5TT=$3

# Defaults
keep_tmp=0
tmpDir=/tmp/create5TT_`hostname`_`random_string`



print_help()
{
  
 echo "

  `basename $0` <fa[.gz]> <adc[.gz]> <output5TT.nii[.gz]>

Obtain a five-tissue-type file (5TT) for performing ACT and SIFT
in mrtrix.

This script is capable of obtaining a decent tissue segmentation without
the need to provide T1 images, and thus everything related to ACT and SIFT
can run on the native DWI space. This is particularly useful if you do not
have geometric distortion correction, since co-registering T1 and DWI 
is bound to be sub-optimal.

Both FA and ADC maps must be skull-stripped.

Please note that this script takes a while to run (~1 hour), 
but you can easily send it to the cluster using fsl_sub.

Options:

  -tmpDir <path/to/tmpDir>
  -keep_tmp



Requirements: fsl (tested on version 5). 
              This will provide FAST and FIRST to do the actual segmentation.



LU15 (0N(H4
INB, UNAM
August 2014
lconcha@unam.mx
"
}


print_step()
{
echo "
##################################
[STEP] $1
##################################
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
  -tmpDir)
    nextarg=`expr $i + 1`
    eval tmpDir=\${${nextarg}}
  ;;
  -keep_tmp)
    keep_tmp=1
  ;;
  esac
  i=$[$i+1]
done


mkdir $tmpDir



print_step "Run FAST to obtain GM, WM and CSF tissue segmentations"
my_do_cmd fast -v \
  -t 2 \
  -N \
  -S 2 \
  -o ${tmpDir}/fast \
  $adc \
  $fa
# organize the pve volumes in ordert to simulate a T1 volume
my_do_cmd fslmaths ${tmpDir}/fast_pve_0 -mul 3 ${tmpDir}/wm_pve
my_do_cmd fslmaths ${tmpDir}/fast_pve_1 -mul 2 ${tmpDir}/gm_pve
my_do_cmd fslmerge -t ${tmpDir}/all_pves_modulated ${tmpDir}/wm_pve ${tmpDir}/gm_pve
my_do_cmd fslmaths ${tmpDir}/all_pves_modulated -Tmean ${tmpDir}/pve_modulated_mean
# make your own xfm to std, because sometimes first makes weird things
atlas=${FSLDIR}/data/standard/MNI152_T1_1mm_brain.nii.gz
my_do_cmd flirt \
  -in ${tmpDir}/pve_modulated_mean \
  -ref $atlas \
  -omat ${tmpDir}/pve_modulated_to_std.mat \
  -out ${tmpDir}/pve_modulated_to_std \
  -dof 7





print_step "Run FIRST to obtain subcortical GM segmentations"
my_do_cmd run_first_all \
    -i ${tmpDir}/pve_modulated_mean \
    -o ${tmpDir}/first \
    -b -d \
    -a ${tmpDir}/pve_modulated_to_std.mat




print_step "Compile volumes and create 5TT file"
my_do_cmd my_do_cmd fslmerge \
        -t ${tmpDir}/allFirst \
        ${tmpDir}/first*first.nii
my_do_cmd my_do_cmd fslmaths \
        ${tmpDir}/allFirst.nii.gz \
        -Tmax -thr 1 -bin \
        ${tmpDir}/allFirst_max
my_do_cmd my_do_cmd 5ttgen -info \
        ${tmpDir}/fast_pve_2.nii \
        ${tmpDir}/fast_pve_1.nii \
        ${tmpDir}/fast_pve_0.nii \
        ${tmpDir}/allFirst_max.nii \
        $out5TT



if [ $keep_tmp -ne 0 ]
then
  echo "  [INFO] Will not remove $tmpDir" 
else
  rm -fR $tmpDir
fi


