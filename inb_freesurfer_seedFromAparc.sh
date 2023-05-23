#!/bin/bash
FSLOUTPUTTYPE=NIFTI
source `which my_do_cmd`

subject=$1



fakeflag=""
lmax=4
runTracto=0
seedsPerVoxel=5
seedsPerArea=10000
forcePerVoxel=0
merge=0
streamtrackOptions=""
segmentation=aparc+aseg
keepTMP=0
logfile=${SUBJECTS_DIR}/${subject}/dti/aparc_seeding.log



tmpDir=${SUBJECTS_DIR}/${subject}/tmp/seeding

print_help()
{
echo "
`basename $0` <subjid> [options]

Options:
-fake          : Do a dry run.
-2009s         : Use the 2009s parcellation (more regions).
                 Default is to use the 2005 labels.
-seedsPerVoxel : How many seeds to plant per voxel.
                 Be careful, as large cortical regions will result in 
                 several thousand seeds and it will take a long time.
                 Default is $seedsPerVoxel .
                 This switch supercedes seedsPerArea.
-seedsPerArea  : How many seeds to plant in a cortical area.
                 The number of voxels included divides the number of seeds
                 to get the number of seeds per voxel.
                 Default is $seedsPerArea .
-merge         : Produce a 4D file in the end with the tractography over time.
-streamtrackOptions <\"list of other options for streamtrack\"> 
                    (use streamtrack --help to see them all).
-keepTMP       : Do not remove the tmp directory located at:
                 $tmpDir .


Luis Concha
INB
2012
"

}


if [ $# -lt 1 ] 
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
  -2009s)
    segmentation="aparc.a2009s+aseg"
  ;;
  -seedsPerVoxel)
    nextarg=`expr $i + 1`
    eval seedsPerVoxel=\${${nextarg}}
    forcePerVoxel=1
  ;;
  -seedsPerArea)
    nextarg=`expr $i + 1`
    eval seedsPerArea=\${${nextarg}}
  ;;
  -merge)
    merge=1
  ;;
  -streamtrackOptions)
    nextarg=`expr $i + 1`
    eval streamtrackOptions=\${${nextarg}}
  ;;
  -keepTMP)
    keepTMP=1
  ;;
  esac
  i=$[$i+1]
done




aparc_dti=${SUBJECTS_DIR}/${subject}/dti/${segmentation}_native_dti_space.nii
CSD=`ls ${SUBJECTS_DIR}/${subject}/dti/dti_CSD?.nii.gz`
mask=${SUBJECTS_DIR}/${subject}/dti/nodif_brain_mask.nii
fa=${SUBJECTS_DIR}/${subject}/dti/dti_fa.nii.gz

# Start the log file
date > logfile
echo "$0 $@" >> $logfile
echo " " >> $logfile


my_do_cmd mkdir -p $tmpDir


if [ ! -f $CSD ]
then
    echo "  ERROR: Did not find CSD file. Bye."
    exit 2
fi
if [ ! -f $aparc_dti ]
then
    echo "  ERROR: Did not find Automatic Parcellation in DTI space file. Bye."
    exit 2
fi
if [ ! -f $fa ]
then
    echo "  ERROR: Did not find FA file. Bye."
    exit 2
fi



if [ ! -d ${SUBJECTS_DIR}/${subject}/dti/tractography ]
then
  mkdir -p ${SUBJECTS_DIR}/${subject}/dti/tractography
fi



LUT=$FREESURFER_HOME/FreeSurferColorLUT.txt
echo "LUT is $LUT"


seedOrderFile=${SUBJECTS_DIR}/${subject}/dti/tractography/seedOrder.txt
if [ -f $seedOrderFile ]; then rm $seedOrderFile;fi


if [[ "$segmentation" == "aparc+aseg" ]]
then
  stringLUT="  ctx-"
elif [[ "$segmentation" == "aparc.a2009s+aseg" ]] 
then
  stringLUT="  ctx_"
else
  echo "ERROR: Cannot recognize the type of parcellation." 
  echo "       Options are aparc+aseg OR aparc.a2009s"
  echo "       The default is aparc+aseg, use the -2009s switch for the other one."
  exit 1
fi


grep $stringLUT  $LUT | while read line
do
  ID=`echo $line | awk '{print $1}'`
  structure=`echo $line | awk '{print $2}'`
  echo ""
  echo "Attempting to seed from $structure, ID = $ID"

  # now let's tear apart the aparc and seed one by one.
  seedfile=$tmpDir/seed_${ID}.nii
  fslmaths $aparc_dti -thr $ID -uthr $ID -bin $seedfile
  if [ ! -f $seedfile ]; then echo "File not created: $seedfile"; continue;fi
  nVoxels=`fslstats $seedfile -V | awk '{print $1}'`
  if [ $nVoxels -gt 0 ]
  then
    tckOUT=${tmpDir}/seed_${ID}.tck
    pOUT=${SUBJECTS_DIR}/${subject}/dti/tractography/seed_${ID}_p.nii
    numberOfSeeds=$seedsPerArea
    if [ $forcePerVoxel -eq 1 ]
    then
      numberOfSeeds=$(($nVoxels * $seedsPerVoxel))
    fi
    echo "Will start seeding from $nVoxels voxels (a total of $numberOfSeeds tracks will be generated)."
    my_do_cmd $fakeflag streamtrack "$streamtrackOptions" \
                          -seed $seedfile \
                          -number $numberOfSeeds \
                          -mask $mask \
                          SD_PROB \
                          $CSD \
                          $tckOUT
    my_do_cmd $fakeflag tracks2prob \
                        -fraction \
                        -template $fa \
                        $tckOUT $pOUT
    #rm -f $tckOUT
    echo "$ID,$structure,$pOUT" >> $seedOrderFile
  else
    echo "  No voxels to seed from."
  fi
done


if [ $merge -eq 1 ]
then
  # let's merge the p clouds into a 4D file
  awk -F, -O '{print $3}' $seedOrderFile > ${tmpDir}/flist
  my_do_cmd $fakeflag fslmerge -t \
            ${SUBJECTS_DIR}/${subject}/dti/tractography/tractos.nii \
            `transpose_table.sh ${tmpDir}/flist`
  my_do_cmd $fakeflag fslmaths ${SUBJECTS_DIR}/${subject}/dti/tractography/tractos.nii.gz \
                      -Tmean \
                      ${SUBJECTS_DIR}/${subject}/dti/tractography/tractos_mean.nii
fi

echo "Zipping files..."
gzip ${SUBJECTS_DIR}/${subject}/dti/tractography/*.nii


if [ $keepTMP -eq 1 ]
then
  echo "Keeping tmp directory: $tmpDir ." 
else
  rm -fR $tmpDir
fi

echo "Done."