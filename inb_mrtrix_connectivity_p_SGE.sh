#!/bin/bash
source `which my_do_cmd`
FSLOUTPUTTYPE=NIFTI

seed=$1
fa=$2
CSD=$3
track_p=$4
n=$5
nprime=$6
#tmpDir=/tmp/p_connectivity_`random_string`
out_null_track=${track_p%.nii*}_null.tck
out_real_track=${track_p%.nii*}_real.tck
matlabCommand=/home/inb/lconcha/fmrilab_software/myMatlab/bin/matlab


p_thresh=0.05

print_help()
{
echo "
`basename $0` <seed.nii> <fa.nii> <CSD.nii> <result_p> <n> <nprime> [-options]

***************************************************************
This version provides parallelization (one job per seed voxel).
***************************************************************

 seed                   : The seed region for tracking purposes. 
                          The same seed is used with the real data and the isotropic data.
 fa                     : An FA map from which these tracks come from (to get resolution info).
 CSD                    : The CSD volume from which tracking is performed. 
                          A synthetic, isotropic CSD volume is created with the same dimensions internally.
 result_p.nii           : Output p map.
 n                      : Number of seeds to plant per voxel in the seed region with the real CSD.
 nprime                 : Number of seeds to plant per voxel in the isotropic data.
                          Keep in mind that nprime >> n in order for p values to be meaningful.
                          Normally, nprime is around 10 to 20 times the value of n.

 Options:
 -h|-help                           : Show this message.
 -save_null_track <out.tck>         : Save the track derived from isotropic data.
 -streamtrack_options \"<OPTIONS>\"   : Pass all the options you would give to streamtrack to 
                                      create your track (e.g. -include, -mask, -exclude, etc).
                                      The exact same set of tracking restrictions are applied to the 
                                      real data, as well as to the isotropic data.
 -p_thresh <float>                  : p value that you want to use for thresholding at each seed.
                                      The minimum p value after all seeds have been propagated is the end
                                      result (note that you should use some sort of Bonferroni correction after).
                                      Default is $p_thresh
 -count_per_cluster                 : Specify that n and nprime are both to be divided by the number of
                                      seed voxels. Default is to seed n seeds per voxel.
 -threshold_percent <float>         : Remove any voxels with visitation counts that are below 
                                      this percentage of seeded tracks.
 -keep_tmp
 -tmpDir <fullPath>                 : Specify a temp directory (needs to be NFS accessible!)
                                      PLEASE NOTE: Errors will occur if tmpDir is not available to the cluster via NFS!
 -matlabCommand </path/to/matlab/bin/matlab> : In case you need a different version.
                                      Default is $matlabCommand
 -clobber

.----------------------------------------------------------------------------------.
|  Adapted from:                                                                   |
|  Morris, Embleton and Parker.                                                    |
|  Probabilistic fibre tracking: Differentiation of connections from chance events.|
|  Neuroimage 42, 1329-1339. 2008.                                                 |
.----------------------------------------------------------------------------------.

Implemented by Luis Concha after lots of probability theory help and advice from Leopoldo Gonzalez Santos.
Instituto de Neurobiología, Universidad Nacional Autonoma de México.
October, 2012.

NOTE 1: REQUIRES MATLAB WITH THE IMAGE PROCESSING TOOLBOX (bwlabeln function, in particular).
Note 2: If seeding from more than one voxel, the resulting p per voxel will be the minimum of all iterations.
        (a p map is computed per seed voxel internally).

EXAMPLE:

`basename $0` rPLIC.nii proc_fa.nii proc_CSD6.nii rPLIC_p.nii 100 10000 -keep_tmp -streamtrack_options \"-mask mask.nii\"

 Luis Concha
 INB, Jan 2011

"
}





######## Display welcome message
started=`date`
echo "----------------------------------------------"
echo "Starting processing of `basename $0`"
echo "  Command was `basename $0` $@"
echo "  Started at `date`"
echo "  User: `whoami`"
echo "  Node: `uname -n`"
echo "  PID:   $$" 
echo ""
echo "----------------------------------------------"


if [ $# -lt 6 ] 
then
	echo " ERROR: Need more arguments..."
	print_help
	exit 1
fi

#if [ ${#tmpDir} -eq 0 ]
#then
#  echo "  ERROR: You MUST supply a temp directory that is NFS accessible."
#  exit 1
#fi


declare -i i
i=1
hasNullTrack=0
saveNullTrack=0
keep_tmp=0
mask_by_bonferroni=1
saveRealTrack=0
divideSeedNumByClusterSize=0
threshPercent=0
quiet="-quiet"
clobber=0
for arg in "$@"
do
  case "$arg" in
  -h|-help) 
    print_help
    exit 1
  ;;
  -save_null_track)
    nextarg=`expr $i + 1`
    eval out_null_track=\${${nextarg}}
    echo "Will save null track to $out_null_track" 
    saveNullTrack=1
  ;;
  -save_real_track)
    nextarg=`expr $i + 1`
    eval out_real_track=\${${nextarg}}
    echo "Will save seeded track to $out_real_track" 
    saveRealTrack=1
  ;;
  -keep_tmp)
    keep_tmp=1
  ;;
  -tmpDir)
    nextarg=`expr $i + 1`
    eval tmpDir=\${${nextarg}}
  ;;
  -streamtrack_options)
    nextarg=`expr $i + 1`
    eval streamtrack_options=\${${nextarg}}
    echo "streamtrack_options are $streamtrack_options"
#     echo "temp breakpoint!"
#     exit 2
  ;;
  -p_thresh)
    nextarg=`expr $i + 1`
    eval p_thresh=\${${nextarg}}
  ;;
  -count_per_cluster)
    divideSeedNumByClusterSize=1
  ;;
  -threshold_percent)
    nextarg=`expr $i + 1`
    eval threshPercent=\${${nextarg}}
    echo "threshold Percent is $threshPercent"
  ;;
  -matlabCommand)
    nextarg=`expr $i + 1`
    eval matlabCommand=\${${nextarg}}
    echo "matlabCommand is $matlabCommand"
  ;;
  -no_quiet)
    quiet=""
  ;;
  -clobber)
    clobber=1
  ;;
  esac
  i=$[$i+1]
done


if [ -d $tmpDir ]
then
  if [ $clobber -eq 0 ]
  then
    echo "ERROR: Temp dir already exists $tmpDir"
    exit 2
  else
    rm $tmpDir/*
  fi
fi


echo "Copying $CSD to temporary directory to speed things up later."
mrconvert $CSD ${tmpDir}/CSD.nii
CSD=${tmpDir}/CSD.nii

echo "Copying $fa to temporary directory to speed things up later."
mrconvert $fa ${tmpDir}/fa.nii
fa=${tmpDir}/fa.nii


## make an isotropic CSD
echo "Making an isotropic CSD"
isoCSD=${tmpDir}/isoCSD.nii
mrconvert $CSD ${tmpDir}/orig_CSD.nii
octave --silent --eval "
[hdr,csd] = niak_read_nifti('${tmpDir}/orig_CSD.nii');
isoCSD = zeros(size(csd));
isoCSD(:,:,:,1) = 1;
hdr.file_name = '$isoCSD';
niak_write_nifti(hdr,single(isoCSD));
"



#### Seed loop
echo "Preparing job files"
job_array_commands=${tmpDir}/job_array_commands.txt
if [ -f $job_array_commands ]
then
  rm $job_array_commands
fi
my_do_cmd inb_split_seeds.sh $seed ${tmpDir}/voxel_world
nSeeds=`wc -l ${tmpDir}/voxel_world_seeds.txt | awk '{print $1}'` 
s=1
while read LINE
do
  thisCommand=${tmpDir}/seed_command_`zeropad $s 7`.sh
  echo "hostname" > $thisCommand
  echo "date" >> $thisCommand

  x=`echo $LINE | awk -F, '{print $4}'`
  y=`echo $LINE | awk -F, '{print $5}'`
  z=`echo $LINE | awk -F, '{print $6}'`
  r=`echo $LINE | awk -F, '{print $7}'`
  this_seed="$x,$y,$z,$r"
  echo "  [SEED $s / $nSeeds  ($this_seed)]"
  if [ $divideSeedNumByClusterSize -eq 1 ]
  then
    actual_n=$(($n / $nSeeds))
    actual_nprime=$(($nprime / $nSeeds))
  else
    actual_n=$n
    actual_nprime=$nprime
  fi
  echo streamtrack $quiet \
            -seed $this_seed \
            -number $actual_n \
            $streamtrack_options \
            SD_PROB \
            $CSD \
            ${tmpDir}/`zeropad $s 7`_real.tck >> $thisCommand
  echo streamtrack $quiet \
            -seed $this_seed \
            -number $actual_nprime \
            $streamtrack_options \
            SD_PROB \
            $isoCSD \
            ${tmpDir}/`zeropad $s 7`_null.tck >> $thisCommand
 
  echo tracks2prob $quiet -template $fa ${tmpDir}/`zeropad $s 7`_real.tck ${tmpDir}/`zeropad $s 7`_real_n.nii >> $thisCommand
  echo tracks2prob $quiet -template $fa ${tmpDir}/`zeropad $s 7`_null.tck ${tmpDir}/`zeropad $s 7`_null_n.nii >> $thisCommand
  
  
  ## Create v_null
  echo fslmaths \
            ${tmpDir}/`zeropad $s 7`_null_n.nii \
            -mul $actual_n \
            -div $actual_nprime \
            ${tmpDir}/`zeropad $s 7`_null_v.nii >> $thisCommand
  
  ## Compute p.
  echo "$matlabCommand -nodisplay -nojvm -r \"p = tracto_p_poisson('$this_seed','${tmpDir}/`zeropad $s 7`_real_n.nii','${tmpDir}/`zeropad $s 7`_null_v.nii',[$p_thresh],true,'${tmpDir}/`zeropad $s 7`_p.nii');exit\"" >> $thisCommand
s=$(($s+1))
  chmod +x $thisCommand
  echo $thisCommand >> $job_array_commands
done < ${tmpDir}/voxel_world_seeds.txt
#### end seed loop




echo "---                    ---"
echo "Submiting job array $job_array_commands"
echo "---  "
id_job_array=`fsl_sub -t $job_array_commands -l $tmpDir -N seedjob`


echo " Queuing post-processing stage until job $id_job_array finishes."
fsl_sub -j $id_job_array -l $tmpDir -N seedpost \
  inb_mrtrix_connectivity_p_SGE_postproc.sh \
  $tmpDir $track_p $p_thresh \
  $fa $out_null_track \
  $out_real_track $threshPercent \
  $n $keep_tmp

echo "Use qstat to find out if your jobs have finished. Bye."

