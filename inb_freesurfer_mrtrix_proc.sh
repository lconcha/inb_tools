#!/bin/bash
source `which my_do_cmd`

subject=$1


fakeflag=""
lmax=6
runTracto=0



print_help()
{
echo "
`basename $0` <subjid> [options]

Options:
-lmax <int>
-runTracto  : Will run tractography from the automatic parcellation as seeds.

Luis Concha
INB
2012
"

}


######### Check if help is needed
if [ $# -lt 1 ] 
then
  echo "  ERROR: Need more arguments..."
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
  -lmax)
    nextarg=`expr $i + 1`
    eval lmax=\${${nextarg}}
  ;;
  -fake)
    fakeflag="-fake"
  ;;
  -runTracto)
    runTracto=1
  ;;
  esac
  i=$[$i+1]
done



dti=${SUBJECTS_DIR}/${subject}/dti/dti.nii.gz
encoding=${SUBJECTS_DIR}/${subject}/dti/dti_encoding.b
outbase=${SUBJECTS_DIR}/${subject}/dti/dti
mask=${SUBJECTS_DIR}/${subject}/dti/dti_mask.nii.gz

my_do_cmd $fakeflag inb_mrtrix_proc.sh \
			$dti \
			$encoding \
			$outbase \
			-mask $mask \
			-niigz -est_lmax $lmax -lmax $lmax -tensor_metrics





if [ $runTracto -eq 1 ]
then
  echo "STARTING TRACTOGRAPHY (order pizza or at least a coffee)."
  inb_freesurfer_seedFromAparc.sh
fi
