#!/bin/bash
source `which my_do_cmd`
source $FMRILAB_CONFIGFILE
export FSLOUTPUTTYPE=NIFTI

waitTime=$1
tracks=$2
subj=$3
outConMat=$4
regions=$5

echo "Begining filtering."
echo "  host      : `hostname`"
echo "  tracks    : $tracks"
echo "  subj      : $subj"
echo "  outConMat : $outConMat"
echo "  regions   : $regions"
echo "  time      : `date`"
echo ""
which fslroi
which track_info
echo "------------------------------------"
echo ""


# avoid collisions from all nodes trying to copy the files to /tmp
echo "  waiting $waitTime seconds to start ..."
sleep $waitTime
echo "  OK let us begin."




tmpDir=/tmp/filter_`random_string`
mkdir -v $tmpDir



mask=${SUBJECTS_DIR}/${subj}/dti/dti_mask.nii.gz
wmMask=${SUBJECTS_DIR}/${subj}/dti/dti_wmMask.nii.gz
aparc=${SUBJECTS_DIR}/${subj}/dti/aparc.a2009s+aseg_native_dti_space.nii.gz


isOK=1
for f in $tracks $mask $wmMask $aparc
do
  if [ ! -f $f ]
  then
     echo "  FATAL ERROR: Could not find $f"
     isOK=0
  fi
done

if [ $isOK -eq 0 ]
then
  echo "  MISSION ABORT!. I repeat, MISSION ABORT!".
  rm -fRv $tmpDir
  exit 2
fi


# copy things to a local tmp
cp -v $tracks ${tmpDir}/tracks.tck
tracks=${tmpDir}/tracks.tck
my_do_cmd mrconvert -quiet -datatype uint8 $mask ${tmpDir}/mask.nii
mask=${tmpDir}/mask.nii
my_do_cmd mrconvert -quiet -datatype uint8 $wmMask ${tmpDir}/wmMask.nii
wmMask=${tmpDir}/wmMask.nii
my_do_cmd fslmaths $aparc -mul 1 ${tmpDir}/aparc
aparc=`imfullname ${tmpDir}/aparc`

nTracksFull=`track_info $tracks | grep " count" | awk '{print $2}'`

echo "After copying to a tmp directory, files are:"
echo "  tracks    : $tracks ($nTracksFull streamlines)"
echo "  mask      : $mask"
echo "  wmMask    : $wmMask"
echo "  aparc     : $aparc"
echo ""



cat $regions | while read line
do
  i=`echo $line | awk -F, '{print $1}'`
  j=`echo $line | awk -F, '{print $2}'`
  i_file=$tmpDir/i.nii
  j_file=$tmpDir/j.nii
  tracks_ij=${tmpDir}/tracks_ij.tck

  my_do_cmd $fake fslmaths \
    $aparc \
    -thr $i -uthr $i -bin \
    $i_file
  my_do_cmd $fake fslmaths \
    $aparc \
    -thr $j -uthr $j -bin \
    $j_file
  for f in $i_file $j_file
  do
    if [ ! -f $f ]
    then
      echo "  ERROR: Could not find $f"
      echo "     \-> cleaning up and QUITTING NOW."
      rm -fRv $tmpDir
      exit 2
    fi
  done
  echo "  filtering $tracks with $i_file and $j_file to $tracks_ij (do not expect stdout)..."
  filter_tracks -quiet \
     -include $i_file \
     -include $j_file \
     $tracks \
     $tracks_ij &> /dev/null
  if [ ! -f $tracks_ij ]
  then
     echo "Whoa_NoTrack:$tracks_ij"
  fi
  nTracks=`track_info $tracks_ij | grep " count" | awk '{print $2}'`
  echo "$i,$j,$nTracks" | tee -a $outConMat

done


rm -fRv $tmpDir


