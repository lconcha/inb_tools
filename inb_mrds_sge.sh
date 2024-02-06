#!/bin/bash

#!/bin/bash
source `which my_do_cmd`

help(){
  echo "


Fit multi-tensors using multi-resolution discrete search (MRDS) within a mask.

Since MRDS is a bit slow, processing of a large number of voxels is divided into
many jobs with fewer voxels across a parallel computing environment managed through SGE.

Requires: SGE, fsl_sub


How to use:
  `basename $0` [options] <dwi> <scheme> <mask> <outbase> <n_voxels_per_job> <scratch_dir>

Provide all image files as .nii or .nii.gz (dwi and mask).

<scheme> is a nx4 file with bvecs and bvals, a-la mrtrix grad table. Make sure that the
         vector orientations are correct by first examining output of the command dti,
         specifically the PDD_CARTESIAN file by displaying it as fixels in mrview.

n_voxels_per_job : Number of voxels to estimate MRDS per job. 
                   If your mask has 1000 voxels and n_voxels_per_job=100, then
                   the estimation of MRDS will be split across 10 different computers
                   running in parallel.
                   Recommended value: 100 to 1000 (divide the number of voxels in your mask
                   by the number of jobs you desire, considering the capabilities of your 
                   computing cluster).
scratch_dir     : A temporary directory to put the partial results before being
                   concatenated into the outbase_ files.
                   Needs to be a cluster-accessible folder (i.e., somewhere in /misc).


Options:

-r <file>          Provide a response function (obtained through command dti).
                   If not specified, then this script will calculate it.
                   Note that if you want this script to obtain the response file, then
                   the mask provided should include regions of high anisotropy (single fiber population).
-k                 Keep (do not delete) temporary dir crated within the scratch_dir.



Note:    MRDS cannot handle DWI data sets without b=0 volumes. 
         The Bruker scanner provides bvals that include diffusion gradient sensitization
         from all gradients, including the spatial encoding gradients and crushers, and
         therefore there are no b=0 bvals, but rather a very small b value (e.g b=28 s/mm2).
         This script will automatically find the lowest bvalue and turn it to zero.

Warning: If you did not acquire b=0 volumes, then don't use this script!


This script wraps the MRDS functions by Ricardo Coronado.To cite:
Coronado-Leija, Ricardo, Alonso Ramirez-Manzanares, and Jose Luis Marroquin. 
  Estimation of individual axon bundle properties by a Multi-Resolution Discrete-Search method.
  Medical Image Analysis 42 (2017): 26-43.
  doi.org/10.1016/j.media.2017.06.008



LU15 (0N(H4
INB UNAM
May 2023
lconcha@unam.mx
  "
}


if [ $# -lt 5 ]
then
  echolor red "Not enough arguments"
	help
  exit 2
fi

export SGE_O_SHELL=/bin/bash

response=""
keep_tmp=0
while getopts "r:k" options
do
  case $options in
    r)
      response_file=${OPTARG}
      if [ ! -f $response ]; then 
        echo "Error: File does not exist: $response "
        exit 2
      fi
      response=$(cat $response_file | awk '{OFS = "," ;print $1,$2}')
      echolor green "[INFO] Response file is $response_file"
      echolor green "[INFO] Response provided is $response"
      shift;shift
    ;;
    :)
      echo "Error: -${OPTARG} requires an argument."
      exit 2
    ;;
    k)
      echolor green "[INFO] Will not remove temp directory."
      keep_tmp=1
      shift
    ;;
    *)
      echo "Error: Unknown option"
      exit 2
    ;;
  esac
done



dwi=$1
scheme=$2
mask=$3
outbase=$4
n_voxels_per_job=$5
scratch_dir=$(readlink -f $6)


echolor yellow "
  dwi                       : $dwi
  scheme                    : $scheme
  mask                      : $mask
  outbase                   : $outbase
  n_voxels_per_job          : $n_voxels_per_job
  scratch_dir               : $scratch_dir
"


commands_to_check="mdtmrds pigz"

isOK=1
for comm in $commands_to_check
do
  echo "Looking for $comm"
  if ! command -v $comm &> /dev/null
  then
      echolor red "[ERROR] Command not found: $comm"
      isOK=0
  fi
done

if [ $isOK -eq 0 ]
then
  exit 2
fi


if [ ! -d $scratch_dir ]
then
  echolor red "[ERROR] scratch_dir does not exist: $scratch_dir"
  exit 2
fi




tmpDir=$(mktemp -d --tmpdir=${scratch_dir})
echolor cyan "[INFO] tmpDir is $tmpDir"




shells=`mrinfo -quiet -bvalue_scaling false -grad $scheme $dwi -shell_bvalues`
firstbval=`echo $shells | awk '{print $1}'`
if (( $(echo "$firstbval > 0 " | bc -l)  ))
then
  echolor orange "Lowest bvalue is not zero, but $firstbval .  Will change to zero. "
  sed -i -e "s/${firstbval}/0.0000/g" $scheme
fi


if [ -z "$response" ]
then
  my_do_cmd dti \
    -mask $mask \
    -response 0 \
    -correction 0 \
    -fa -md \
    $dwi \
    $scheme \
    ${outbase}
  echolor yellow "[INFO] Command dti has finished"
  nAnisoVoxels=`fslstats ${outbase}_DTInolin_ResponseAnisotropicMask.nii -V | awk '{print $1}'`
  if [ $nAnisoVoxels -lt 1 ]
  then
    echolor red "[ERROR] Not enough anisotropic voxels found for estimation of response. Found $nAnisoVoxels"
  fi
  echolor yellow "Getting lambdas for response (from $nAnisoVoxels voxels)"
  response=`cat ${outbase}_DTInolin_ResponseAnisotropic.txt | awk '{OFS = "," ;print $1,$2}'`
fi

echolor yellow "[INFO] Gzipping all nii files that start with $outbase"
pigz -v ${outbase}*.nii

echolor yellow "Response:  $response"


my_do_cmd masksplit.sh $mask $n_voxels_per_job ${tmpDir}/mask4D.nii
nVolsROI=$(mrinfo -size ${tmpDir}/mask4D.nii | awk '{print $4}')
echo "nVolsROI is $nVolsROI"


sleep_multiplier=1; #seconds to be multiplied by frame number
                    # used to stagger jobs and avoid disk read

#### JOB: Calculate MRDS
list_mrds_jobs=${tmpDir}/mrds_job_array
echo "date" > $list_mrds_jobs; # the very first job always fails inexplicably
for frame in $(seq -f "%05g" 0 $(($nVolsROI -1)))
do
    this_frame_job=${tmpDir}/job_frame_${frame}
    thismask=${tmpDir}/mask_${frame}.nii.gz
    my_do_cmd mrconvert -quiet -coord 3 $frame ${tmpDir}/mask4D.nii $thismask
    
    rand_in_range=$(shuf -i 1-${nVolsROI} -n 1)
    this_sleep=$(mrcalc $rand_in_range $sleep_multiplier -mul)
    echo "[INFO] Job $frame will sleep $this_sleep seconds to avoid disk read congestion"

    echo "
    #!/bin/bash 

    sleep $this_sleep

    local_tmpDir=/tmp/mrds_$(whoami)_${RANDOM}
    mkdir -pv \$local_tmpDir

    mdtmrds \
    $dwi \
    $scheme \
    \${local_tmpDir}/mrds_job_${frame} \
    -correction 0 \
    -response $response \
    -mask $thismask \
    -modsel bic \
    -fa -md -mse \
    -method diff 1
    
    pigz \${local_tmpDir}/*.nii
    cp \${local_tmpDir}/*.nii.gz ${tmpDir}/
    rm -fR \${local_tmpDir}
    
    " > $this_frame_job
    chmod +x $this_frame_job
    echo $this_frame_job >> $list_mrds_jobs
done

nVols=`wc -l $list_mrds_jobs`
echolor reverse "  Submitting $nVols mrds jobs"
jidPar=$(fsl_sub -s smp,4 -N mrdsPar -l $tmpDir -t $list_mrds_jobs)
echolor cyan "[INFO] Job ID for array of mrds jobs: $jidPar"

#### JOB: Concatenate
concatenate_mrds_job=${tmpDir}/mrds_job_concatenate
echo "#!/bin/bash


tmpDir=\$(mktemp -d)
for f in ${tmpDir}/mrds_job_00001_MRDS_*.nii.gz
do
  ndim=\$(mrinfo -ndim \$f)
  ff=\$(basename \$f)
  fout=${outbase}_\${ff#mrds_job_00001_}
  echo fout is \$fout
  mrcat -quiet -axis \$ndim \${f/_00001_/*} \${tmpDir}/\${ff%.nii.gz}.mif
  mrmath -quiet -axis \$ndim \${tmpDir}/\${ff%.nii.gz}.mif sum \$fout
done
rm -fR \${tmpDir}
" > $concatenate_mrds_job
chmod +x $concatenate_mrds_job
#echolor green "--------- $concatenate_mrds_job --------"
#cat $concatenate_mrds_job
#echolor green "-- END -- $concatenate_mrds_job --------"
jidCat=$(fsl_sub -j $jidPar -N mrdsCat -l $tmpDir $concatenate_mrds_job)
echolor cyan "[INFO] Job ID for concatenating mrds files: $jidCat and is waiting for $jidPar to finish"





if [ $keep_tmp -eq 0 ]; then
  delete_job=${tmpDir}/mrds_job_delete
  echo "#!/bin/bash
  rm -fR $tmpDir
  " > $delete_job
  chmod +x $delete_job
  fsl_sub -j $jidCat -N mrdsDel -l $tmpDir $delete_job
else
  echolor green "[INFO] Will not delete $tmpDir"
fi
