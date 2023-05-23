#!/bin/bash
FSLOUTPUTTYPE=NIFTI
source `which my_do_cmd`



print_help()
{
echo "
`basename $0` <subjid> 

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

############# Defaults
keepTMP=0
fakeflag=""
connecivityThreshold=0.001
FAthreshold=0.2
########################


declare -i i
i=1
for arg in "$@"
do
  case "$arg" in
  -h|-help) 
    print_help
    exit 1
  ;;
  -keepTMP)
    keepTMP=1
  ;;
  esac
  i=$[$i+1]
done





subject=$1

tmpDir=${SUBJECTS_DIR}/${subject}/tmp/dti_metrics
my_do_cmd mkdir -p $tmpDir



fa=${SUBJECTS_DIR}/${subject}/dti/dti_fa.nii.gz
my_do_cmd $fakeflag fslmaths $fa -thr $FAthreshold -bin ${tmpDir}/famask.nii
famask=${tmpDir}/famask.nii


if [ ! -f $fa ]
then
    echo "  ERROR: Did not find FA file. Bye."
    exit 2
fi



# Prepare a result file with a header
resultFile=${SUBJECTS_DIR}/${subject}/dti/dti_aparc_stats.csv
metrics="fa adc l1 l2 l3"
if [ -f $resultFile ]; then rm $resultFile; fi

mm=""
for m in $metrics
do
  mm="$mm,$m"
done
echo "ID,Region$mm" > $resultFile




# Now get some mean values. We will reuse the metric file
metricfile=${tmpDir}/metric.nii
cat ${SUBJECTS_DIR}/${subject}/dti/tractography/seedOrder.txt | while read line
do
  ID=`echo $line | awk -F, '{print $1}'`
  region=`echo $line | awk -F, '{print $2}'`
  tracto=`echo $line | awk -F, '{print $3}'`.gz
  echo " " 
  echo "Working on $region" 
  my_do_cmd $fakeflag fslmaths $tracto \
                      -mul $famask \
                      -thr $connecivityThreshold \
                      ${tmpDir}/stats_mask.nii
  maxP=`fslstats ${tmpDir}/stats_mask.nii -R | awk '{print $2}'` 
  my_do_cmd $fakeflag fslmaths ${tmpDir}/stats_mask.nii \
                      -div $maxP \
                      ${tmpDir}/stats_mask_W.nii
  printf "%s,%s" $ID $region >> $resultFile
  for metric in $metrics
  do
    if [ ! -f ${SUBJECTS_DIR}/${subject}/dti/dti_${metric}.nii.gz ]
    then
	echo "ERROR: Cannot find metric file: ${SUBJECTS_DIR}/${subject}/dti/dti_${metric}.nii"
	exit 2
    fi
    # Weigh the DTI metric by the connectivity probability
    my_do_cmd $fakeflag fslmaths \
                       ${tmpDir}/stats_mask_W.nii \
                       -mul \
                       ${SUBJECTS_DIR}/${subject}/dti/dti_${metric}.nii.gz \
                       $metricfile
    # Now get the stats
    thismean=`fslstats $metricfile -k ${tmpDir}/stats_mask_W.nii -m`
    printf ",%f" $thismean >> $resultFile
  done
    printf "\n" >> $resultFile
done








if [ $keepTMP -eq 1 ]
then
  echo "Keeping tmp directory: $tmpDir ." 
else
  rm -fR $tmpDir
fi

echo "Done."