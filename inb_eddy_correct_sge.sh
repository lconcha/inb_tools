#!/bin/bash
source `which my_do_cmd`
export FSLOUTPUTTYPE=NIFTI
# fakeflag="-fake"
fakeflag=""

DWI=$1
DWIout=$2
ref=$3
method=$4

keep_tmp=0


print_help()
{

 echo "

  `basename $0` <dwiIN.mif> <DWIOUT.mif> <ref|ref.mif> <method> [Options]

Use affine registration for each frame of a DWI data set to a reference volume.

The reference volume can be either:
  a) An index (starting at zero) of the dwiIN.mif data set.
  b) An image derived from the dwiIN (for example, the average b=0 volume).

method: A string of either:
  a) mrtrix. Uses mrregister. It is slower and not thoroughly tested. May not work.
  b) fsl (recommended) Uses flirt.


Options:
-keep_tmp
-rotbvecs



LU15 (0N(H4
lconcha@unam.mx
INB, UNAM
August, 2017
"
}



if [ $# -lt 4 ]
then
	echo " ERROR: Need more arguments..."
	print_help
	exit 2
fi

## defaults
keep_tmp=0
rotbvecs=0
##########

declare -i arg_index
arg_index=1
for arg in "$@"
do
  case "$arg" in
  -h|-help)
    print_help
    exit 1
  ;;
  -keep_tmp)
    keep_tmp=1
  ;;
  -rotbvecs)
    rotbvecs=1
  ;;
  esac
  arg_index=$[$arg_index+1]
done





if [[ "$method" = "mrtrix" ]]
then
  nFrames=`mrinfo -size $DWI | awk '{print $4}'`
  for f in `seq 0 $(($nFrames -1))`
  do
    frame=`zeropad $f 4`
    my_do_cmd $fakeflag mrconvert -coord 3 $frame -axes 0,1,2 $DWI tmp_$$_${frame}.mif
    my_do_cmd $fakeflag mrregister tmp_$$_${frame}.mif $ref \
      -type affine  \
      -transformed tmp_$$_${frame}_t.mif  \
      -affine tmp_$$_${frame}_t.xfm \
      -affine_init_translation none \
      -affine_init_rotation none
  done
  my_do_cmd $fakeflag mrcat tmp_$$_*_t.mif tmp_$$_cat.mif
  my_do_cmd $fakeflag mrinfo -export_grad_mrtrix tmp_$$_grad.txt $DWI
  my_do_cmd $fakeflag mrconvert -grad tmp_$$_grad.txt tmp_$$_cat.mif $DWIout
  my_do_cmd $fakeflag rm tmp_$$_*
  exit 0
fi





if [[ "$method" = "fsl" ]]
then
  tmpDir=./tmp_eddy_$$
  mkdir $tmpDir

  my_do_cmd mrinfo -export_grad_mrtrix ${tmpDir}/grad.b \
                   -export_grad_fsl ${tmpDir}/bvec ${tmpDir}/bval $DWI


  filename=$(basename "$1")
  extension="${filename#*.}"
  filename="${filename%.*}"

  input=$1
  output=$2
  ref=$3


  if [ "$ref" -eq $ref ] 2>/dev/null
  then
    echo "$ref is an integer !!"
    my_do_cmd $fakeflag mrconvert -coord 3 $ref $DWI ${tmpDir}/ref.mif
    ref=${tmpDir}/ref.mif
  fi



 input_tmp=${tmpDir}/input.nii
 mrconvert $input $input_tmp
 ref_tmp=${tmpDir}/ref.nii
 mrconvert $ref $ref_tmp

  my_do_cmd $fakeflag fslsplit $input_tmp ${tmpDir}/tmp
  full_list=`ls ${tmpDir}/tmp????.nii*`

  jobfile_par=${tmpDir}/jobfile_par

list_ec_files=""
  for i in $full_list ; do
        echo ${FSLDIR}/bin/flirt \
            -in $i \
            -ref $ref_tmp \
            -nosearch \
            -o ${i%.nii}_ec.nii \
            -omat ${i%.nii}_ec.mat \
            -paddingsize 1 >> $jobfile_par
        list_ec_files="$list_ec_files ${i%.nii}_ec.nii"
  done
nVols=`wc -l $jobfile_par`
echolor reverse "  Submitting $nVols registration jobs"
jidPar=`fsl_sub -N eddyPar -t $jobfile_par -l $tmpDir`
echo "mrcat -axis 3  $list_ec_files ${tmpDir}/output.mif" > ${tmpDir}/mrcat.job
jidCat=`fsl_sub -N eddyCat -l $tmpDir -j $jidPar -t ${tmpDir}/mrcat.job`

jtowait=$jidCat
if [ $rotbvecs -eq 1 ]
then
  ecclog=${tmpDir}/ecclog
  echo "inb_mats2ecclog.sh $tmpDir $ecclog ; \
        rotbvecs ${tmpDir}/bvec ${tmpDir}/bvec_rotated $ecclog" > ${tmpDir}/rotbvecs.job
  jidRot=`fsl_sub -N eddyrot -l $tmpDir -j $jidCat -t ${tmpDir}/rotbvecs.job`
  jtowait=$jidRot
fi

  if [ $rotbvecs -eq 1 ]
  then
    bvecToUse=${tmpDir}/bvec_rotated
  else
    bvecToUse=${tmpDir}/bvec
  fi
  echo "mrconvert -fslgrad $bvecToUse ${tmpDir}/bval ${tmpDir}/output.mif $output" >> ${tmpDir}/conv.job
  echolor yellow "  Job eddyConv will wait for jid $jtowait to finish"
  jidConv=`fsl_sub -l $tmpDir -N eddyConv -j $jtowait -t ${tmpDir}/conv.job`

  if [ $keep_tmp -eq 0 ]
  then
    echolor cyan "  will remove temp directory $tmpDir"
    echo "rm -fR  $tmpDir" > ${tmpDir}/clean.job
    jidClean=`fsl_sub -l /dev/null -N eddyClean -j $jidConv -t ${tmpDir}/clean.job`
  else
    echolor cyan " Will not delete temporary directory: $tmpDir"
  fi

echolor orange " Hint: Type '"'watch qstat'"' to keep an eye on your jobs."
 exit 0
fi
