#!/bin/bash
source `which my_do_cmd`
export FSLOUTPUTTYPE=NIFTI


subj=$1
tracks=$2
conMat=$3
regions=/home/inb/lconcha/fmrilab_software/tools/connectivityMatrix_freesurfer_aparc2009_possibleConnections.txt

nJobs=400
fake=""
logDirName=`pwd`



print_help()
{
  echo "
  `basename $0` <subjID> <tracks.tck> <conMat.txt> [-options]

 subjID      : A subject within \$SUBJECTS_DIR
 tracks.tck  : Pre-computed whole-brain tractography. Use >250,000 streamlines.
 conMat.txt  : Output connectivity matrix in list form.


 Options:
 -logDirName <path> : Where to put the logs. Default is `pwd`
 -nJobs <int> : Number of connections to compute per node in SGE cluster. 
                Currently set to $nJobs.
 -regions <file> A file of possible connections to investigate.
                 It is a csv file with the aparc regions that are to be connected.
                 Example:
		  8,10
		  8,11
		  8,12
		  9,10
		  9,11
                  ... 

 

 NOTES:

 * Expects \$SUBJECTS_DIR to be exported.
 * tracks.tck can be large files! >1GB is normal. Try to put them in a tmp folder to avoid backing them up.
 * This script will call inb_mrtrix_aparc_conMat_fewRegions.sh as a job array.
 * SGE cluster must be up and running.
 * Files should be accessible through the cluster.
 * Expects a file with the regions to connect in: 
     $regions

 * Files that need to be within the \${SUBJECTS_DIR}/\${subjID}/dti directory [1]:
    mask    = dti_mask.nii.gz
    wmMask  = dti_wmMask.nii.gz
    CSD     = dti_CSD6.nii.gz
    aparc   = aparc.a2009s+aseg_native_dti_space.nii.gz


 [1] See also:
     inb_freesurfer_dti_registration.sh
     inb_mrtrix_proc.sh


  Luis Concha
  INB, UNAM
  March, 2014.			
"
}



declare -i i
i=1
skip=1
for arg in "$@"
do
  case "$arg" in
    -h|-help) 
      print_help
      exit 1
    ;;
    -nJobs)
      nextarg=`expr $i + 1`
      eval nJobs=\${${nextarg}}
    ;;
    -regions)
      nextarg=`expr $i + 1`
      eval regions=\${${nextarg}}
    ;;
    -logDirName)
      nextarg=`expr $i + 1`
      eval logDirName=\${${nextarg}}
    ;;
    esac
    i=$[$i+1]
done




if [ $# -lt 3 ] 
then
	echo " ERROR: Need more arguments..."
	print_help
	exit 1
fi



if [ -f $conMat ]
then
  echo " File exists, cannot continue: $conMat"
  exit 2
fi







tmpbase=${logDirName}/tmp_${subj}_`random_string`

echo "Splitting the regions file into separate jobs..."
split -d -l $nJobs $regions ${tmpbase}_regions
nJobs=`ls ${tmpbase}_regions* | wc -l`
echo "  Will submit $nJobs jobs"


declare -i waitTime
# many nodes will try to copy the same file at once to /tmp, so waitTime staggers the requests.
waitTime=0
track_fileSize=`du $tracks | awk '{print $1}'`
netSpeed=30000
transferTime=`echo "$track_fileSize / $netSpeed" | bc`
proc_jobfile=${tmpbase}_proc_jobfile.txt
for r in  ${tmpbase}_regions*
do
  echo "inb_mrtrix_aparc_conMat_fewRegions.sh $waitTime $tracks $subj ${r}_con $r" >> $proc_jobfile
  waitTime=$[$waitTime+$transferTime]
done

# Prepare a post-processing job
nTracks=`track_info $tracks | grep " count" | awk '{print $2}'`
post_jobfile=${tmpbase}_post_jobfile.sh
echo "#!/bin/bash"  > $post_jobfile
echo "echo \# track_file: $tracks > $conMat" >> $post_jobfile
echo "echo \# track_number: $nTracks >> $conMat" >> $post_jobfile
echo "echo \# regions_file: $regions >> $conMat" >> $post_jobfile
echo "echo \# format of this file: regionA,regionB,nConnections >> $conMat" >> $post_jobfile
echo "cat ${tmpbase}_regions*_con >> $conMat" >> $post_jobfile
echo "rm -fv ${tmpbase}*" >> $post_jobfile
chmod +x $post_jobfile


# submit jobs
echo "Submitting jobs..."
proc_ID=`fsl_sub -l $logDirName -N f${subj} -t $proc_jobfile`
echo "  array job ID is $proc_ID"
fsl_sub -l $logDirName -j $proc_ID -N post${subj} $post_jobfile



