#!/bin/bash
source `which my_do_cmd`
FSLOUTPUTTYPE=NIFTI

seed=$1
fa=$2
CSD=$3
track_p=$4
n=$5
nprime=$6
tmpDir=/tmp/p_connectivity_`random_string`
save_null_track=0
out_null_track=${track_p%.nii*}_null.tck
out_real_track=${track_p%.nii*}_real.tck


p_thresh=0.05

print_help()
{
echo "
`basename $0` <seed.nii> <fa.nii> <CSD.nii> <result_p> <n> <nprime> [-options]

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
 -tmpDir <fullPath>                 : Specify a temp directory (default is a random dir within /tmp)
 -matlabCommand </path/to/matlab/bin/matlab> : In case you need a different version.

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


declare -i i
i=1
hasNullTrack=0
saveNullTrack=0
keep_tmp=0
mask_by_bonferroni=1
saveRealTrack=0
divideSeedNumByClusterSize=0
threshPercent=0
matlabCommand=matlab11
quiet=""
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
  -quiet)
    quiet="-quiet"
  ;;
  -clobber)
    clobber=1
  ;;
  esac
  i=$[$i+1]
done


if [ -d $tmpDir ]
then
  if [ $clobber -eq 1 ]
  then 
    rm -f $tmpDir/*
  else
    echo "ERROR: Temp dir already exists $tmpDir"
    exit 2
  fi
else
  mkdir $tmpDir
fi


if [ -f $track_p ]
then
  if [ $clobber -eq 1 ]
  then
     rm -f $track_p
  else
     echo "ERROR: $track_p already exists!"
     exit 2
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




nSeeds=`fslstats $seed -V | awk '{print $1}'` 
my_do_cmd streamtrack $quiet \
	  -seed $seed \
	  -number $n \
	  $streamtrack_options \
	  SD_PROB \
	  $CSD \
	  ${tmpDir}/real.tck
my_do_cmd streamtrack $quiet \
	  -seed $seed \
	  -number $nprime \
	  $streamtrack_options \
	  SD_PROB \
	  $isoCSD \
	  ${tmpDir}/null.tck

my_do_cmd tracks2prob $quiet -template $fa ${tmpDir}/real.tck \
  ${tmpDir}/real_n.nii
my_do_cmd tracks2prob $quiet -template $fa ${tmpDir}/null.tck \
  ${tmpDir}/null_n.nii

## Create v_null
my_do_cmd fslmaths \
	  ${tmpDir}/null_n.nii \
	  -mul $n \
	  -div $nprime \
	  ${tmpDir}/null_v.nii

## Compute p.
$matlabCommand -nodisplay -nojvm <<EOF
p = tracto_p_poisson_noLoop('$seed','${tmpDir}/real_n.nii','${tmpDir}/null_v.nii',[$p_thresh],true,'$track_p');
EOF




# Show the threshold after Bonferroni correction
bp=`echo $p_thresh/$nSeeds | bc -l`
echo "--------------------------------"
echo "Bonferroni corrected threshold"
echo "for an original p value of $p_thresh :"
echo "  $bp"
echo "--------------------------------"



if [ $save_null_track -eq 1 ]
then
  cp -v ${tmpDir}/null.tck $out_null_track
  cp -v ${tmpDir}/null_n.nii ${out_null_track%.tck}_n.nii
fi

cp -v ${tmpDir}/real.tck $out_real_track
cp -v ${tmpDir}/real_n.nii ${out_real_track%.tck}_n.nii



if [ $threshPercent -gt 0 ]
then
  echo " ** Computing a threshold ** " 
  echo "   thr = ($n x $threshPercent) / 100 " 
  thr=$(( (${n} * $threshPercent) / 100 ))
  echo "   thr = $thr"
else
  thr=$threshPercent
fi

echo "thr = $thr"

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
  echo "Did not remove temporary directory: $tmpDir" 
fi

