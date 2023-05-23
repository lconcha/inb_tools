#!/bin/bash
FSLOUTPUTTYPE=NIFTI
source `which my_do_cmd`

########################
subject=$1
########################


fakeflag=""
keepTMP=0
tmpDir=${SUBJECTS_DIR}/${subject}/tmp/behrens_classifier
FAthreshold=0.2
streamtrackOptions=""
seedsPerVoxel=5
seedsPerArea=5000
keepTracks=0
keepTracks_p=0
noMaskBySeed=0
forcePerVoxel=0
simplify_aparc=1
hastargetRegions=0



print_help()
{
echo "
`basename $0` <subjid> [options]

Options:
-fake          : Do a dry run.
-seedsPerVoxel : How many seeds to plant per voxel.
                 Be careful, as large seed regions will result in 
                 several thousand seeds and it will take a long time.
                 Default is $seedsPerVoxel .
                 This switch supercedes seedsPerArea.
-seedsPerArea  : How many seeds to plant in a seeding area.
                 The number of voxels included divides the number of seeds
                 to get the number of seeds per voxel.
                 Default is $seedsPerArea . 
                 If -seedsPerVoxel is not specified then this is the
                 actual number of seed to be distributed uniformly across al the seed region.
-streamtrackOptions <\"list of other options for streamtrack\"> 
                    (use streamtrack --help to see them all).
-tmpDir        : Specify a temporary directory.
                 Default is $tmpDir
-keepTMP       : Do not remove the tmpDir directory.
-keepTracks    : Put the .tck files in the dti/tractography directory.
-keepTracks_p  : Put the connectivity probability clouds in the said directory.              
-noMaskBySeed  : Do not mask the parcellation by the seed.
-classificationMask <mask.nii.gz> : Provide a mask to classify (default is both thalami).
                                 This must be in native DTI space.
-out <result_classified_mask.nii.gz>  : Provide the name of the classified mask. 
                                     Default is ?h_thalamus_classified.nii.gz
-noSimplify    : Do not simplify the aparc parcellation.
                 Default is to simplify it in order to mimic Behren's paper.
-targetRegions <list.txt> : Provide a text file in which all the target regions
                            (i.e., their aparc IDs are provided). 
                            The file is a simple text file with one line and n columns.

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
    tmpDir=\${${nextarg}}
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
    eval classificationMask=\${${nextarg}}
    hasClassMask=1
  ;;
  -out)
    nextarg=`expr $i + 1`
    eval out=\${${nextarg}}
    hasOUT=1
  ;;
  -noSimplify)
     simplify_aparc=0
  ;;
  -targetRegions)
    nextarg=`expr $i + 1`
    eval targetRegions=\${${nextarg}}
    hastargetRegions=1
  ;;
  esac
  i=$[$i+1]
done



# Check sanity of arguments
if [ $hasClassMask -eq 1 -a $hasOUT -eq 0 ]; then
  echo "  ERROR: Use of -out is mandatory when using -classificationMask. Quitting."
  exit 1
fi

if [ $hasOUT -gt 0 -a -f $out ]; then
    echo "  ERROR: File exists and not overwriting: $out"
    exit 1
fi



if [ ! -d ${SUBJECTS_DIR}/${subject}/dti/tractography/ ]
then
  mkdir ${SUBJECTS_DIR}/${subject}/dti/tractography/
fi


fa=${SUBJECTS_DIR}/${subject}/dti/dti_fa.nii.gz
mask=${SUBJECTS_DIR}/${subject}/dti/dti_mask.nii.gz
CSD=${SUBJECTS_DIR}/${subject}/dti/dti_CSD6.nii.gz
aparc=${SUBJECTS_DIR}/${subject}/dti/aparc+aseg_native_dti_space.nii.gz
LUT=$FREESURFER_HOME/FreeSurferColorLUT.txt

logfile=${SUBJECTS_DIR}/${subject}/dti/tractography/behrens_classifier.log

date > $logfile


if [ -f $logfile ]; then rm $logfile;fi

my_do_cmd $fakeflag -log $logfile mkdir -p $tmpDir



## Simplify the parcellation if needed. If not, then assign the original aparc.
if [ $simplify_aparc -eq 1 ]
then
  aparc_simple=${SUBJECTS_DIR}/${subject}/dti/aparc_simple_native_dti_space.nii.gz
  inb_freesurfer_aparc_simplify.sh $aparc $aparc_simple
else
  aparc_simple=$aparc
fi


if [ $hastargetRegions -eq 0 ]
then
  ## Find out how many targets we will have
  max=`fslstats $aparc_simple -R | awk '{print $2}'`
  seq -s " " 1 2 $max > ${tmpDir}/lh_targets.txt
  seq -s " " 2 2 $max > ${tmpDir}/rh_targets.txt
else
  echo "A list of targests was specified: $targetRegions"
  cp -v $targetRegions ${tmpDir}/lh_targets.txt
  cp -v $targetRegions ${tmpDir}/rh_targets.txt
fi


# Get the thalami
my_do_cmd $fakeflag -log $logfile fslmaths $aparc -thr 10 -uthr 10 -bin ${tmpDir}/lh_thalamus.nii.gz
my_do_cmd $fakeflag -log $logfile fslmaths $aparc -thr 49 -uthr 49 -bin ${tmpDir}/rh_thalamus.nii.gz




tmpTrack=${tmpDir}/temp_track.tck
for hemi in lh rh
do

	if [ $hasClassMask -eq 1 ]
	then
	  seedfile=$classificationMask
	else
	  seedfile=${tmpDir}/${hemi}_thalamus.nii.gz
        fi
	if [ $hasOUT -gt 0 -a -f $out ]; then
	  echo "  ERROR: File exists and not overwriting: $out"
	  exit 1
	fi
	echo seedfile is $seedfile

	# calculate the number of seeds
	nVoxels=`fslstats $seedfile -V | awk '{print $1}'`
	numberOfSeeds=$seedsPerArea
    if [ $forcePerVoxel -eq 1 ]
    then
      numberOfSeeds=$(($nVoxels * $seedsPerVoxel))
    fi
	

	transpose_table.sh ${tmpDir}/${hemi}_targets.txt | while read id
	do
		tmpTrack_p=${tmpDir}/${hemi}_thalamus_to_${id}_p.nii.gz
		
		my_do_cmd $fakeflag -log $logfile fslmaths $aparc_simple -thr $id -uthr $id -bin ${tmpDir}/target.nii.gz

		my_do_cmd $fakeflag -log $logfile -no_stderr streamtrack $streamtrackOptions \
			-seed $seedfile \
			-number $numberOfSeeds \
			-mask $mask \
			-include ${tmpDir}/target.nii.gz \
			-stop \
			-initcutoff 0.0001 \
			SD_PROB \
			$CSD \
			$tmpTrack
	    my_do_cmd $fakeflag -log $logfile -no_stderr tracks2prob -quiet \
			-fraction \
			-template $fa \
			$tmpTrack $tmpTrack_p
		if [ $keepTracks -eq 1 ]
		then
			my_do_cmd $fakeflag -log $logfile cp -v $tmpTrack ${SUBJECTS_DIR}/${subject}/dti/tractography/${hemi}_thalamus_to_$id.tck
		fi
		if [ $keepTracks_p -eq 1 ]
		then
			my_do_cmd $fakeflag -log $logfile cp -v $tmpTrack_p ${SUBJECTS_DIR}/${subject}/dti/tractography/${hemi}_thalamus_to_${id}_p.nii.gz
		fi
    done



    # Now we do the classification using find_the_biggest and make a log
    targets=`ls ${tmpDir}/${hemi}_thalamus_to_*_p.nii.gz`
    my_do_cmd $fakeflag -log $logfile find_the_biggest $targets ${tmpDir}/${hemi}_classified.nii.gz
    targetsLog=${SUBJECTS_DIR}/${subject}/dti/tractography/${hemi}_thalamus_targets.txt
    date > $targetsLog
    echo `whoami`@`uname -n` >> $targetsLog
    echo "Seeding from ${hemi}_thalamus to targets:" >> $targetsLog
    declare -i i
    i=1
    for f in $targets
    do
    	echo "$i,$f" >> $targetsLog
    	i=$[$i+1]
    done

    if [ $hasOUT -eq 0 ]
    then
      out=${SUBJECTS_DIR}/${subject}/dti/tractography/${hemi}_thalamus_classified.nii.gz
    fi


    # Mask the classification
    if [ $noMaskBySeed = 0 ]
    then
    	my_do_cmd $fakeflag -log $logfile fslmaths ${tmpDir}/${hemi}_classified.nii.gz -mul $seedfile $out
    else
    	my_do_cmd $fakeflag -log $logfile mv -v ${tmpDir}/${hemi}_classified.nii.gz $out
    fi


    if [ $hasOUT -gt 0 -a -f $out ]; then
	  exit 1
    fi

done


if [ $keepTMP -eq 0 ]
then
	rm -fR $tmpDir
else
	echo "tmpDir was not removed: $tmpDir"
fi


