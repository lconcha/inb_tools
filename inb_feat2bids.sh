#!/bin/bash
fsf=$1
id=$2
bidsDir=$3
taskName=$4





help() {
echo "
`basename $0` <fsf> <id> <bidsDir> <taskName>

fsf     : The .fsf file inside a .feat directory.
id      : The ID that will be given to the subject inside the bids format.
bidsDir : Where the bids data sets will be stored
taskName: Name of the task, will be used to identify according to bids nomenclature.
          This can be anything, but do not use underscores or funny characters.
          Examples: sternberg, oddball, visualcue, etc.

Note: The T1 images normally included in a .fsf file have already been brain extracted.
      Therefore, you must go and change the T1w file in the output bids directory for each subject.
      Alternatively, copy and modify the fsf file before you run this script, pointing to the raw T1.


LU15 (0N(H4
June, 2018
INB, UNAM
lconcha@unam.mx

"
}



if [ "$#" -lt 2 ]; then
  echo "[ERROR] - Not enough arguments"
  help
  exit 2
fi





cInfo="cyan"
cError="red"


tmpDir=/tmp/feat2bids_$$
mkdir $tmpDir


#check that this is a first level alanysis
level=$(grep "set fmri(level) 1" $fsf | awk '{print $3}')
echolor $cInfo " Analysis level is $level"



# prepare the bids subject directory
if [ ! -d ${bidsDir}/sub-${id}/func ]
then
  mkdir -p ${bidsDir}/sub-${id}/func
fi
if [ ! -d ${bidsDir}/sub-${id}/anat ]
then
  mkdir -p ${bidsDir}/sub-${id}/anat
fi



# get the functional images
epis=$(grep "set feat_files" $fsf | awk '{print $3}' | tr -d \")
epis=$(imfullname $epis)
if [ -f "$epis" ]
then
  echolor $cInfo " Functional images: $epis"
else
  echolor $cError " Functional images: $epis"
fi

# get the anatomical volume
t1=$(grep "set highres_files" $fsf | awk '{print $3}' | tr -d \")
t1=$(imfullname $t1)
if [ -f "$t1" ]
then
  echolor $cInfo " Anatomical images: $t1"
else
  echolor $cError " Anatomical images: $t1"
fi


# copy the images in the right place
#cp -v $epis ${bidsDir}/sub-${id}/func/sub-${id}_task-${taskName}_bold.nii.gz
#cp -v $t1   ${bidsDir}/sub-${id}/anat/sub-${id}_T1w.nii.gz
ln -s $epis ${bidsDir}/sub-${id}/func/sub-${id}_task-${taskName}_bold.nii.gz
ln -s $t1   ${bidsDir}/sub-${id}/anat/sub-${id}_T1w.nii.gz


# get the regressors
nRegressors=$(grep "set fmri(evs_orig)" $fsf | awk '{print $3}')
echolor $cInfo " There are $nRegressors regressors"


printf '%s\t%s\t%s\n' onset duration trial_type > ${tmpDir}/events.tsv
for r in `seq 1 $nRegressors`
do
  txtRegressor=$(grep "set fmri(custom$r)" $fsf | awk '{print $3}' | tr -d \")
  regressorFile=${outbase}regressor_${r}.txt
  nEvents=`cat $txtRegressor | wc -l`
  EVtitle=$(grep "set fmri(evtitle$r)" $fsf | awk '{print $3}' | tr -d \")
  echolor $cInfo "   Regressor $r   : $txtRegressor"
  echolor $cInfo "   Regressor Name : $EVtitle"
  echolor $cInfo "      $nEvents events"
  awk -v title="$EVtitle" 'BEGIN {OFS="\t"}{print $1,$2,title}' $txtRegressor  >> ${tmpDir}/events.tsv
done



# write the events in bids style
tsv=${bidsDir}/sub-${id}/func/sub-${id}_task-${taskName}_events.tsv
echolor cyan "  Writing the tsv file: $tsv"
cat ${tmpDir}/events.tsv | sort -n | tr -s '\t' >> $tsv






rm -fR $tmpDir

