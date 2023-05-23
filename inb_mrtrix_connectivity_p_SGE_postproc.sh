#!/bin/bash
source `which my_do_cmd`
FSLOUTPUTTYPE=NIFTI


tmpDir=$1
track_p=$2
p_thresh=$3
fa=$4
out_null_track=$5
out_real_track=$6
threshPercent=$7
n=$8
keep_tmp=$9


nVols=`ls ${tmpDir}/0*_p.nii | wc -l`
echo "There are $nVols _p.nii files"
echo "Obtaining the average of these $nVols files and putting it to $track_p"


# unfortunately we have to make a for loop, because nVols usually is >1000, and bash will complain of too many arguments, or mrcat will complain of too many open files.
firstFile=`ls ${tmpDir}/0*_p.nii | head -n 1`
my_do_cmd fslmaths $firstFile -mul 0 -add 1 ${tmpDir}/accumulated.nii
for f in ${tmpDir}/0*_p.nii
do
#   my_do_cmd mradd -quiet ${tmpDir}/accumulated.nii $f ${tmpDir}/accumulated2.nii
  my_do_cmd fslmaths ${tmpDir}/accumulated.nii -min $f ${tmpDir}/accumulated2.nii
  mv -v ${tmpDir}/accumulated2.nii ${tmpDir}/accumulated.nii
done
mv -v ${tmpDir}/accumulated.nii $track_p

# Show the threshold after Bonferroni correction
bp=`echo $p_thresh/$nSeeds | bc -l`
echo "--------------------------------"
echo "Bonferroni corrected threshold"
echo "for an original p value of $p_thresh :"
echo "  $bp"
echo "--------------------------------"





my_do_cmd select_tracks $quiet ${tmpDir}/*_null.tck $out_null_track
my_do_cmd tracks2prob $quiet \
	  -template $fa \
	  $out_null_track \
	  ${out_null_track%.tck}_n.nii
my_do_cmd select_tracks $quiet ${tmpDir}/*_real.tck $out_real_track
my_do_cmd tracks2prob $quiet \
	  -template $fa \
	  $out_real_track \
	  ${out_real_track%.tck}_n.nii

if [ $threshPercent -gt 0 ]
then
  echo " ** Computing a threshold ** " 
  echo "   thr = ($n x $threshPercent) / 100 " 
  thr=$(( (${n} * $threshPercent) / 100 ))
  echo "   thr = $thr"
else
  thr=$threshPercent
fi

my_do_cmd fslmaths \
          ${out_real_track%.tck}_n.nii \
          -thr $thr -bin \
          ${tmpDir}/real_n_mask

bp_inv=`echo "1 - $bp" | bc -l`
my_do_cmd fslmaths \
          $track_p -sub 1 -abs \
          -thr $bp_inv -bin \
          ${tmpDir}/bp_mask

my_do_cmd fslmaths \
          $track_p \
          -sub 1 -abs \
          -mul ${tmpDir}/bp_mask \
          -mul ${tmpDir}/real_n_mask \
          ${track_p%.nii*}_1-p_thr

my_do_cmd fslmaths \
          ${tmpDir}/bp_mask \
          -mul ${tmpDir}/real_n_mask \
          -mul ${out_real_track%.tck}_n.nii \
          ${out_real_track%.tck}_n_thr.nii \
 



if [ $keep_tmp -eq 0 ]
then
  echo "Removing temporary directory: $tmpDir" 
  rm -fR $tmpDir
else
  #rm -f ${tmpDir}/*.tck
  echo "Did not remove temporary directory: $tmpDir" 
fi