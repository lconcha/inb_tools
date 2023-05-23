#!/bin/bash
source `which my_do_cmd` 

nMaxTracks=300000
seedsPerVoxel=100
SEED_list=""
AND_list=""
NOT_list=""
OR_list=""
do_prob_map=0
forceLots=0
streamtrackOptions=""
keep_tmp=0

print_help()

{
echo "
`basename $0` <CSD> <OUT.tck> [options]

-seed <.label | .nii>
-ref <imagen.nii>
-or <.label | .nii>
-and <.label | .nii>
-not <.label | .nii>
-seedsPerVoxel <int> (Default is $seedsPerVoxel)
-do_prob_map
-forceLots       Force the generation of more than $nMaxTracks tracks
-streamtrackOptions <\"list of other options for streamtrack\"> 
                    (use streamtrack --help to see them all).
-keep_tmp  Keep the temp directory.
Note that you can combine .label and .nii files. 
For example, you can use:
  `basename $0` CSD.nii thal2motor.tck -seed thalamus.label -ref fa.nii -and motorctx.nii

LU15 (0N(H4
INB
2011
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
  -seed)
  	 nextarg=`expr $i + 1`
    eval SEED=\${${nextarg}}
    SEED_list="$SEED_list $SEED"
   ;;
   -ref)
    nextarg=`expr $i + 1`
    eval ref=\${${nextarg}}
    ;;
    -seedsPerVoxel)
      nextarg=`expr $i + 1`
      eval seedsPerVoxel=\${${nextarg}}
    ;;
    -do_prob_map)
      do_prob_map=1
    ;;
    -forceLots)
      forceLots=1
    ;;
    -streamtrackOptions)
      nextarg=`expr $i + 1`
      eval streamtrackOptions=\${${nextarg}}
    ;;
    -and)
      nextarg=`expr $i + 1`
      eval AND=\${${nextarg}}
      AND_list="$AND_list $AND"
    ;;
    -not)
      nextarg=`expr $i + 1`
      eval NOT=\${${nextarg}}
      NOT_list="$NOT_list $NOT"
    ;;
    -or)
      nextarg=`expr $i + 1`
      eval OR=\${${nextarg}}
      OR_list="$OR_list $OR"
    ;;
    -keep_tmp)
      keep_tmp=1
    ;;
  esac
  i=$[$i+1]
done


CSD=$1
tckOUT=$2



# Make a temp directory
tmpDir=/tmp/mrtrix_proc_$$
mkdir $tmpDir


islabel()
{
    if [ -z `echo $1 | grep .label` ]
    then
		echo 0
    else
		echo 1 
    fi

}


i=0
for f in $SEED_list
do
  if [ `islabel $f` -eq 1 ]
  then
    if [ -z $ref ]
    then
			echo "If using labels, you MUST use the -ref switch."
			exit 1
    fi
    echo "Converting $f to a volume"
    my_do_cmd mri_label2vol --label $f --o ${tmpDir}/SEED_${i}.nii --temp $ref --regheader $ref
  else
    if [[ "${f##*.}" == "gz" ]]
    then 
      uncompressedSeed=${tmpDir}/`random_string`.nii
      echo "Mask is compressed, I will uncompress to $uncompressedSeed"
      gunzip -v -c $f > $uncompressedSeed 
      f=$uncompressedSeed
    fi
    my_do_cmd ln -s `readlink -f $f` ${tmpDir}/SEED_${i}.nii
  fi
  i=$(($i +1))
done


SEED_list=`ls ${tmpDir}/SEED*.nii 2>/dev/null`
if [ -z $SEED_list ]
then
  echo "There are no SEEDs"
else
  FSLOUTPUTTYPE=NIFTI
  nSeeds=`echo $SEED_list | wc -w`
  if [ $nSeeds -gt 1 ]
  then
  		my_do_cmd fslmerge -t ${tmpDir}/SEED.nii $SEED_list
  		my_do_cmd fslmaths ${tmpDir}/SEED.nii -Tmax ${tmpDir}/SEED2.nii
  		my_do_cmd fslmaths ${tmpDir}/SEED2.nii -bin ${tmpDir}/SEEDb.nii
  else
	  	my_do_cmd ln -s $SEED_list ${tmpDir}/SEEDb.nii
  fi
  seedSwitch="-seed ${tmpDir}/SEEDb.nii"
fi

nSeedVoxels=`fslstats ${tmpDir}/SEEDb.nii -V | awk '{print $1}'`
numberOfSeeds=$(($nSeedVoxels * $seedsPerVoxel))

if [ $numberOfSeeds -gt $nMaxTracks ]
then
	if [ $forceLots -eq 0 ]
	then
		echo ""
		echo "  Hello `whoami`:"
		echo "  You are trying to generate $numberOfSeeds tracks."
		echo "  That will take a long time, and I refuse to do it."
		echo "  You can only convince me to generate more than $nMaxTracks by using the -forceLots switch. "
		echo "  Bye."
		rm -fR $tmpDir
		exit 1
	fi
fi



i=0
for f in $AND_list
do
  if [ `islabel $f` -eq 1 ]
  then
      if [ -z $ref ]
      then
	  echo "If using labels, you MUST use the -ref switch."
	  exit 1
      fi
      echo "Converting $f to a volume"
      mri_label2vol --label $f --o ${tmpDir}/AND_${i}.nii --temp $ref --regheader $ref
  else
    if [[ "${f##*.}" == "gz" ]]
    then 
      uncompressedSeed=${tmpDir}/`random_string`.nii
      echo "Mask is compressed, I will uncompress to $uncompressedSeed"
      gunzip -v -c $f > $uncompressedSeed 
      f=$uncompressedSeed
    fi
    my_do_cmd ln -s `readlink -f $f` ${tmpDir}/AND_${i}.nii
  fi
i=$(($i +1))
done

i=0
for f in $NOT_list
do
  if [ `islabel $f` -eq 1 ]
  then
      if [ -z $ref ]
      then
	  echo "If using labels, you MUST use the -ref switch."
	  exit 1
      fi
      echo "Converting $f to a volume"
      mri_label2vol --label $f --o ${tmpDir}/NOT_${i}.nii --temp $ref --regheader $ref
  else
    if [[ "${f##*.}" == "gz" ]]
    then 
      uncompressedSeed=${tmpDir}/`random_string`.nii
      echo "Mask is compressed, I will uncompress to $uncompressedSeed"
      gunzip -v -c $f > $uncompressedSeed 
      f=$uncompressedSeed
    fi
    my_do_cmd ln -s `readlink -f $f` ${tmpDir}/NOT_${i}.nii
  fi
i=$(($i +1))
done



for f in $OR_list
do
  if [ `islabel $f` -eq 1 ]
  then
      if [ -z $ref ]
      then
	  echo "If using labels, you MUST use the -ref switch."
	  exit 1
      fi
      echo "Converting $f to a volume"
      mri_label2vol --label $f --o ${tmpDir}/OR_${i}.nii \
                    --temp $ref --regheader $ref
  else
    if [[ "${f##*.}" == "gz" ]]
    then 
      uncompressedSeed=${tmpDir}/`random_string`.nii
      echo "Mask is compressed, I will uncompress to $uncompressedSeed"
      gunzip -v -c $f > $uncompressedSeed 
      f=$uncompressedSeed
    fi
    my_do_cmd ln -s `readlink -f $f` ${tmpDir}/OR_${i}.nii
  fi
i=$(($i +1))
done

INCLUDE_list=`ls ${tmpDir}/AND*.nii 2>/dev/null`
EXCLUDE_list=`ls ${tmpDir}/NOT*.nii 2>/dev/null`
OR_list=`ls ${tmpDir}/OR*.nii 2>/dev/null`

or=""


if [ -z $OR_list ]
then
  echo "There are no ORs"
else
  FSLOUTPUTTYPE=NIFTI
  echo fslmerge -t ${tmpDir}/OR.nii $OR_list
  fslmerge -t ${tmpDir}/OR.nii $OR_list
  fslmaths ${tmpDir}/OR.nii -Tmax ${tmpDir}/OR2.nii
  fslmaths ${tmpDir}/OR2.nii -bin ${tmpDir}/ORb.nii
  or="-include ${tmpDir}/ORb.nii"
fi






inc=""
exc=""
for f in $INCLUDE_list
do
  inc="$inc -include $f"
done
for f in $EXCLUDE_list
do
  exc="$exc -exclude $f"
done

echo "Will start seeding from $nSeedVoxels voxels (a total of $numberOfSeeds tracks will be generated)."
my_do_cmd streamtrack $inc $exc $or $streamtrackOptions -number $numberOfSeeds $seedSwitch SD_PROB $CSD $tckOUT

if [ $do_prob_map -gt 0 ]
then
  my_do_cmd tracks2prob -fraction -template $ref $tckOUT ${tckOUT%.tck}_p.nii
fi

if [ $keep_tmp -eq 0 ]
then
  rm -fR $tmpDir
else
  echo "Did not remove temp directory: $tmpDir"
  echo "Please remove it manually using rm -fR $tmpDir when you are done."
fi




