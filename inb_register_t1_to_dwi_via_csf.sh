#!/bin/bash
source `which my_do_cmd`
export FSLOUTPUTTYPE=NIFTI


## Defaults
keep_tmp=0
tmpDir=/tmp/dwiRegister_`random_string`


print_help()
{
echo "
`basename $0` <t1> <adc> <outbase> [Options]
 
Note that t1 and adc must be skull-stripped


Options

  -keep_tmp
  -tmpDir </some/folder>

 It is a good idea to keep the tmp directory if you want to use the pve estimations of FAST.

 
 LU15 (0N(H4
 INB, Feb 2015.
 lconcha@unam.mx

"
}


if [ $# -lt 3 ] 
then
	echo " ERROR: Need more arguments..."
	print_help
	exit 1
fi






### Parse arguments
declare -i index
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
    -tmpDir)
      nextarg=`expr $i + 2`
      eval tmpDir=\${${nextarg}}
      echo "  Info: tmpDir is $tmpDir"
    ;;
    esac
    i=$[$i+1]
done
t1=$1
adc=$2
outbase=$3



### Begin work
mkdir $tmpDir

echo "  STEP:  Run FAST on the T1 volume"
my_do_cmd fast -v -S 1 -n 3 -t 1 -I 1 -g -N \
  -o ${tmpDir}/Fast_t1 \
  $t1


echo "  STEP:  Run FLIRT between the t1 CSF map and the ADC map"
my_do_cmd flirt \
  -in ${tmpDir}/Fast_t1_pve_0 \
  -ref $adc \
  -omat ${outbase}_lin.mat \
  -out ${tmpDir}/lin_csf2adc_transformed



echo "  STEP:  Non-linear registration with FNIRT"
my_do_cmd fnirt -v \
  --in=${tmpDir}/Fast_t1_pve_0 \
  --ref=$adc \
  --fout=${outbase}_field \
  --aff=${outbase}_lin.mat


echo "  STEP: Apply the resulting warp field"
my_do_cmd applywarp -v \
  -i $t1 \
  -o ${outbase}_t1_to_dwi \
  -r $adc \
  -w ${outbase}_field



if [ $keep_tmp -eq 1 ]
then
  echo "Keeping tmp dir: $tmpDir"
else
  rm -fR $tmpDir
fi
echo "Done."
