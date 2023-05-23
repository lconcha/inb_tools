#!/bin/bash
FSLOUTPUTTYPE=NIFTI
source `which my_do_cmd`

########################
subject=$1
########################



## Default
fakeflag=""
keepTMP=0
tmpDir=/tmp/${subject}/behrens_classifier_$$
FAthreshold=0.2
streamtrackOptions=""
seedsPerVoxel=5
seedsPerArea=5000
keepTracks=0
keepTracks_p=0
noMaskBySeed=0
forcePerVoxel=0
out=classified
bilateral=0
fraction=0
CSDlmax=8

# Default files needed
aparc=`imfullname ${SUBJECTS_DIR}/${subject}/dti/aparc+aseg_to_avDWI`
fa=`imfullname ${SUBJECTS_DIR}/${subject}/dti/dti_fa`
mask=`imfullname ${SUBJECTS_DIR}/${subject}/dti/dti_mask`
CSD=`imfullname ${SUBJECTS_DIR}/${subject}/dti/dti_CSD${CSDlmax}`
LUT=$FREESURFER_HOME/FreeSurferColorLUT.txt


print_help()
{
echo "
`basename $0` <subjid> -classificationMask <mask.nii.gz> -targetRegions <list.txt> -outDir <directory_name>

-classificationMask <mask.nii.gz> : Provide a mask to classify (default is both thalami).
                                 This must be in native DTI space.
-targetRegions <list.txt> : Provide a text file in which all the target regions
                            (i.e., their aparc IDs are provided). 
                            The file is a simple text file with nAreas lines and nIDs columns.
                            Each line is considered an area, and it conglomerates the IDs in that row.
                            The first column is the name of the area. It is OK to have an area with just one ID.
                            For example, a file containing three regions
                            would look something like this:
                                   frontal 1014 1012 1032 1027 1028 1003 1017 1018
                                   broca 1019 1020
                                   wernicke 1031
-outDir <directory_name>  : The name of the directory that will contain the results.
                            It will be placed within \$SUBJECTS_DIR/\$subject/dti/

Options:

-fake          : Do a dry run.
-aparc <file>  : Use this file to obtain the parcellation of the brain.
                 Please note that any parcellation must obey freesurfer look up table.
                 Default aparc is:
                   \${SUBJECTS_DIR}/\${subject}/dti/aparc+aseg-to_avDWI.nii.gz 
                 and the Freesurfer LUT is:
                   \$FREESURFER_HOME/FreeSurferColorLUT.txt
-seedsPerVoxel : How many seeds to plant per voxel.
                 Be careful, as large seed regions will result in 
                 several thousand seeds and it will take a long time.
                 This switch supercedes seedsPerArea
-seedsPerArea  : How many seeds to plant in a seeding area.
                 The number of voxels included divides the number of seeds
                 to get the number of seeds per voxel.
                 Default is $seedsPerArea . 
                 If -seedsPerVoxel is not specified then this is the
                 actual number of seed to be distributed uniformly across al the seed region.
-streamtrackOptions <\"list of other options for streamtrack\"> 
                    (use streamtrack --help to see them all).
-CSDlmax <int> : The lmax used for spherical deconvolution. 
                 The script will look for a file called \${SUBJECTS_DIR}/\${subject}/dti/dti_CSD\${CSDlmax}
                 Default is $CSDlmax
-tmpDir        : Specify a temporary directory.
                 Default is $tmpDir
-keepTMP       : Do not remove the tmpDir directory.
-keepTracks    : Put the .tck files in the dti/\$outDir directory.
-keepTracks_p  : Put the connectivity probability clouds in the said directory.              
-noMaskBySeed  : Do not mask the parcellation by the seed.
-out <result_classified_mask>  : Provide the name of the classified mask. 
                                 We will take care of the extension.
                                 The default is classified
-bilateral     : If you supply a list of regions for one hemisphere,
                 it will also find those regions of the corresponding hemisphere
                 (assuming they are paired structures).
                 Supply a list of files for the left hemisphere (they all start with 1000).
                 Example: if you supply a list that contains: 
                          1014 1012 1032
                          then the program will make masks of destinations for each ID, as the sum of
                          the left and right hemisphere, so
                          target1 = 1014 OR 2014
                          target2 = 1012 OR 2012
                          target3 = 1032 OR 2032
-fraction      : The probability of connectivity is based on the number of filtered tracks, 
                 not the total number of seeds (which is the default).

Luis Concha
INB
2012
"

}





if [ $# -lt 1 ] 
then
  echo "  ERROR: Need more arguments..."
  print_help
  exit 1
fi





declare -i i
i=1
hasOUT=0
hasClassMask=0
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
  -aparc)
    nextarg=`expr $i + 1`
    eval aparc=\${${nextarg}}
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
  -streamtrackOptions)
    nextarg=`expr $i + 1`
    eval streamtrackOptions=\${${nextarg}}
  ;;
  -keepTMP)
      keepTMP=1
  ;;
  -tmpDir)
    nextarg=`expr $i + 1`
    eval tmpDir=\${${nextarg}}
  ;;
  -keepTracks)
	   keepTracks=1
  ;;
  -keepTracks_p)
	   keepTracks_p=1
  ;;
  -noMaskBySeed)
	   noMaskBySeed=1
  ;;
  -classificationMask)
    nextarg=`expr $i + 1`
    eval seedfile=\${${nextarg}}
    hasClassMask=1
  ;;
  -out)
    nextarg=`expr $i + 1`
    eval out=\${${nextarg}}
    out=`remove_ext $out`
  ;;
  -targetRegions)
    nextarg=`expr $i + 1`
    eval targetRegions=\${${nextarg}}
  ;;
  -outDir)
    nextarg=`expr $i + 1`
    eval outDir=\${${nextarg}}
  ;;
  -bilateral)
    bilateral=1
  ;;
  -fraction)
    fraction=1
  ;;
  -CSDlmax)
    nextarg=`expr $i + 1`
    eval CSDlmax=\${${nextarg}}
    CSD=`imfullname ${SUBJECTS_DIR}/${subject}/dti/dti_CSD${CSDlmax}`
  ;;
  esac
  i=$[$i+1]
done


## Create the tmp directory
my_do_cmd $fakeflag  mkdir -p $tmpDir




# Check sanity of arguments
if [ `imtest ${SUBJECTS_DIR}/${subject}/dti/${outDir}/$out` -gt 0 ]; then
    echo "  ERROR: File exists and not overwriting: ${SUBJECTS_DIR}/${subject}/dti/${outDir}/$out"
    exit 1
fi

echo "tmpDir is $tmpDir"
if [ ! -d ${SUBJECTS_DIR}/${subject}/dti/${outDir}/ ]
then
  mkdir ${SUBJECTS_DIR}/${subject}/dti/${outDir}/
fi





isOK=1
for f in $fa $mask $CSD $aparc $LUT $seedfile $targetRegions
do
  echo "Looking for file: ${f}"
  if [ ! -f $f ]
  then
    echo "CRITICAL ERROR: File does not exist: $f"
    isOK=0
  else
    echo "  got it!"
  fi
done

if [ $isOK -eq 0 ]
then
  exit 2
fi
#### End of sanity checks





# Check the format of the target regions text files
# if [ `wc -l $targetRegions | awk '{print $1}'` -gt 1 ]
# then
#   echo "Warning: Wrong format for $targetRegions"
#   echo "  Do not worry, let me fix it for you..."
#   transpose_table.sh $targetRegions > ${tmpDir}/targetRegions.txt
#   targetRegions=${tmpDir}/targetRegions.txt
#   echo "  targetRegions has been set to $targetRegions"
# fi




logfile=${SUBJECTS_DIR}/${subject}/dti/${outDir}/behrens_classifier.log
if [ -f $logfile ]; then rm $logfile;fi
date > $logfile








echo "A list of targests was specified: $targetRegions"
if [ ! -f $targetRegions ]
then
  echo "CRITICAL ERROR: File does not exist:  $targetRegions"
  exit 2
fi




# calculate the number of seeds
if [ $forcePerVoxel -eq 1 ]
then
  nVoxels=`fslstats $seedfile -V | awk '{print $1}'`
  numberOfSeeds=$(($nVoxels * $seedsPerVoxel))
else
  numberOfSeeds=$seedsPerArea
fi


tmpTrack=${tmpDir}/temp_track.tck
my_do_cmd $fakeflag  streamtrack $streamtrackOptions \
	-seed $seedfile \
	-number $numberOfSeeds \
	-mask $mask \
	-initcutoff 0.0001 \
	SD_PROB \
	$CSD \
	$tmpTrack




#### We begin the loop for the targets
list_of_p_files=${tmpDir}/list_of_p_files.txt
if [ -f  $list_of_p_files ]; then rm  $list_of_p_files;fi
cat $targetRegions | while read row
do
  thisAreaList=""
  thisAreaIDs=""
  echo "  [ row is :  $row ]"
  nColumn=0
  for ID in $row
  do
	nColumn=$(($nColumn + 1))
	if [ $nColumn -eq 1 ]
	then
	  heading=$ID
	  echo "  [ heading is :  $heading ]"
	  continue
	fi

	echo " [ ID is : $ID ] "
        my_do_cmd $fakeflag  fslmaths \
            $aparc \
            -thr $ID -uthr $ID -bin \
            ${tmpDir}/target_${ID}.nii
        thisAreaList="$thisAreaList ${tmpDir}/target_${ID}.nii"
	thisAreaIDs="${thisAreaIDs}_${ID}"
	if [ $bilateral -eq 1 ]
	then
	    contralateral_ID=2${ID:1}
	    my_do_cmd $fakeflag  fslmaths \
		$aparc \
		-thr $contralateral_ID -uthr $contralateral_ID -bin \
		${tmpDir}/target_${contralateral_ID}.nii
	    thisAreaList="$thisAreaList ${tmpDir}/target_${contralateral_ID}.nii"
	    thisAreaIDs="${thisAreaIDs}_${contralateral_ID}"
	fi
  done
  ID="+${heading}"
  my_do_cmd $fakeflag fslmerge -t \
      ${tmpDir}/thisArea_targets_merged.nii \
      $thisAreaList
  my_do_cmd $fakeflag fslmaths \
      ${tmpDir}/thisArea_targets_merged.nii \
      -Tmax -bin \
      ${tmpDir}/target_${ID}.nii


  my_do_cmd $fakeflag  filter_tracks \
          -quiet \
          -include ${tmpDir}/target_${ID}.nii \
          $tmpTrack \
          ${tmpDir}/seed_to_${ID}.tck

  if [ $fraction -eq 0 ]
  then
    my_do_cmd $fakeflag  tracks2prob \
	    -quiet \
	    -template $fa \
	    ${tmpDir}/seed_to_${ID}.tck \
	    ${tmpDir}/seed_to_${ID}_n.nii
    # divide the number of tracks per voxel by the n of seeds used all over.
    my_do_cmd $fakeflag  fslmaths \
	    ${tmpDir}/seed_to_${ID}_n.nii \
	    -div $numberOfSeeds \
	    -mul 100 \
	    ${tmpDir}/seed_to_${ID}_p.nii
  else
    my_do_cmd $fakeflag  tracks2prob \
	    -quiet \
	    -template $fa \
	    -fraction \
	    ${tmpDir}/seed_to_${ID}.tck \
	    ${tmpDir}/seed_to_${ID}_p.nii
  fi
  echo ${tmpDir}/seed_to_${ID}_p.nii >> $list_of_p_files

  if [ $keepTracks -eq 1 ]
  then
	  my_do_cmd $fakeflag  cp -v \
          ${tmpDir}/seed_to_${ID}.tck \
          ${SUBJECTS_DIR}/${subject}/dti/${outDir}/seed_to_${ID}.tck
  fi
done
# end of targets loop


#Now we do the classification using find_the_biggest and make a log
targets=`transpose_table.sh $list_of_p_files`
my_do_cmd $fakeflag  find_the_biggest $targets ${tmpDir}/classified
targetsLog=${SUBJECTS_DIR}/${subject}/dti/${outDir}/targets.txt
date > $targetsLog
echo `whoami`@`uname -n` >> $targetsLog
echo "Seeding was: $seedfile" >> $targetsLog
echo "Targets were, in order:" >> $targetsLog
declare -i i
i=1
for f in $targets
do
    echo "$i,$f" >> $targetsLog
    i=$[$i+1]
done


# Mask the classification
if [ $noMaskBySeed = 0 ]
then
    my_do_cmd $fakeflag  fslmaths \
              ${tmpDir}/classified \
             -mul \
             $seedfile \
             ${SUBJECTS_DIR}/${subject}/dti/${outDir}/$out
else
    my_do_cmd $fakeflag  immv \
              ${tmpDir}/classified \
              ${SUBJECTS_DIR}/${subject}/dti/${outDir}/$out
fi
gzip -v `imfullname ${SUBJECTS_DIR}/${subject}/dti/${outDir}/$out`


if [ $keepTracks_p -eq 1 ]
then
	my_do_cmd $fakeflag  fslmerge -t \
	${SUBJECTS_DIR}/${subject}/dti/${outDir}/seed_to_targets_p.nii \
	$targets
	gzip -v ${SUBJECTS_DIR}/${subject}/dti/${outDir}/seed_to_targets_p.nii
fi



if [ $keepTMP -eq 0 ]
then
	rm -fR $tmpDir
else
	echo "tmpDir was not removed: $tmpDir"
fi


