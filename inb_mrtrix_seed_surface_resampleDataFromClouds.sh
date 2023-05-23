#!/bin/bash
source `which my_do_cmd`
FSLOUTPUTTYPE=NIFTI


print_help()
{
echo "
`basename $0` <someSurfaceWithData.asc> <pCloudsDir> <track_count_threshold> <outbase> <-data someData.nii> [-data someMoreData.nii]

 This scripts assumes you have already ran inb_mrtrix_seed_surface.sh and
 you kept your connectivity clouds in some directory. 
 It is useful for obtaining the values from the volumes again, using a different
 connectivity threshold.

 Luis Concha
 INB, Jan 2013

"
}



if [ $# -lt 6 ] 
then
	echo " ERROR: Need more arguments..."
	print_help
	exit 1
fi


surfWithData=$1
pCloudsDir=$2
track_count_threshold=$3
outbase=$4
keep_tmp=0

tmpDir=/tmp/resample_volumes_`random_string`
mkdir $tmpDir



declare -i i
i=1
dataVolumes="" 
for arg in "$@"
do
  case "$arg" in
  -h|-help) 
    print_help
    exit 1
  ;;
 -data)
    nextarg=`expr $i + 1`
    eval thisData=\${${nextarg}}
    dataVolumes="$dataVolumes $thisData"
  ;;
  -keep_tmp)
    keep_tmp=1
  ;;
  esac
  i=$[$i+1]
done

echo "These are the volumes to be sampled:"
for dv in $dataVolumes
do
  echo "  $dv"
done


#nVertices=`wc -l $valuesPerVertex | awk '{print $1}'`
#echo "There are $nVertices vertices."

cat $surfWithData | while read line
do
  v=`echo $line | awk '{print $1}'`
  zpv=`zeropad $v 7`
  x=`echo $line | awk '{print $2}'`
  y=`echo $line | awk '{print $3}'`
  z=`echo $line | awk '{print $4}'`
  thisPcloud=$pCloudsDir/tmp__tracks_from_surface_$zpv.nii.gz
  if [ -f $thisPcloud ]
  then
    fGlob=`imglob $thisPcloud`
    tmp_pCloud=${tmpDir}/`basename $fGlob`
    fslmaths $thisPcloud -thr $track_count_threshold -bin $tmp_pCloud
    for dv in $dataVolumes
    do
      thisVal=`fslstats $dv -k $tmp_pCloud -m`
      echo "$v $x $y $z $thisVal" | tee -a ${outbase}_`basename $dv`.asc
    done
  else
    echo "  INFO: $thisPcloud does not exist."
    for dv in $dataVolumes
    do
      thisVal="NaN"
      echo "$v $x $y $z $thisVal" | tee -a ${outbase}_`basename $dv`.asc
    done
  fi
done


if [ $keep_tmp -eq 0 ]
then
  rm -fR $tmpDir
else
  my_do_cmd fslmerge -t ${tmpDir}/merged ${tmpDir}/tmp__tracks_from_surface*.nii
  gzip -v ${tmpDir}/*.nii
  echo "INFO: Did not remove tmp directory $tmpDir"
fi


