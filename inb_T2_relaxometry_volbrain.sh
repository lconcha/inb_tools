#!/bin/bash
source `which my_do_cmd`

t1=$1
t2map=$2
volbrain_labels=$3
outbase=$4



print_help()
{
echo "
`basename $0` <t1> <t2map> <volbrain_labels> <outbase>

Get T2 relaxometry of the hippocampus using volBrain[*] labels.

All arguments are compulsory.

t1      : The native T1 volume that was submitted to volBrain
t2map   : The pre-calculated T2 map from the T2_CALC sequence. 
          The Philips scanner normally calculates this for you, but
          it must be extracted from the 4D file using fslroi.
volbrain_labels : The resulting labels from volBrain. 
                  They are generally named something *_lab_n_mmni_fjob*.nii
outbase : Prefix for resulting files.


[*] http://volbrain.upv.es/error.php

 LU15 (0N(H4
 INB, Feb 2015.
 lconcha@unam.mx

"
}



if [ $# -lt 4 ] 
then
	echo " ERROR: Need more arguments..."
	print_help
	exit 1
fi




LabHippoL=11
LabHippoR=12




echo "  Register t2map to T1"
xfm_t2_to_t1=${outbase}_t2_to_t1.mat
my_do_cmd flirt \
  -in $t2map \
  -ref $t1 \
  -dof 6 \
  -cost mutualinfo \
  -searchcost mutualinfo \
  -nosearch \
  -omat $xfm_t2_to_t1 -out ${xfm_t2_to_t1%.mat}.nii.gz


echo " Invert transformation"
xfm_t1_to_t2=${outbase}_t1_to_t2.mat
my_do_cmd convert_xfm \
  -omat $xfm_t1_to_t2 \
  -inverse $xfm_t2_to_t1



echo "  Put the labels into T2 space"
labels_t2=${outbase}_volbrain_t2space.nii.gz
my_do_cmd flirt \
  -in $volbrain_labels \
  -ref $t2map \
  -applyxfm -init $xfm_t1_to_t2 \
  -interp nearestneighbour \
  -out $labels_t2


echo "  Get the T2 values"
L=`fslstats_rois $t2map $labels_t2 $LabHippoL "-m -s -V"`
R=`fslstats_rois $t2map $labels_t2 $LabHippoR "-m -s -V"`


# Report
report=${outbase}_Hippo_T2_report.txt
echo "Structure meanT2 stdT2 volume(vox) volume(mm3)" > $report
echo "HippoLeft $L" >> $report
echo "HippoRight $R" >> $report
column -t $report
