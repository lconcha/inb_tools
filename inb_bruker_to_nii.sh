#!/bin/bash
source `which my_do_cmd`



print_help()
{
  
 echo "

  `basename $0` <2dseq> <out.nii>


Requirements: matlab and Aedes (http://aedes.uef.fi/).

Options:

-inversions '[1 1 1]'    Put between quotes and brackets the vector for gradient flipping.
                            a 1x3 matrix of multipliers in [x y z] form. 
                            For example, to flip the z component, use [1 1 -1]
                            Default is to not flip anything, i.e., [1 1 1].
-onlyGrads               Do not write the nifti file. 
                 

LU15 (0N(H4
INB, UNAM
Feb 2015
lconcha@unam.mx
"
}



if [ $# -lt 2 ] 
then
	echo " ERROR: Need more arguments..."
	print_help
	exit 1
fi



declare -i i
i=1
inversions='[1 1 1]'
write_nifti=true
for arg in "$@"
do
  case "$arg" in
  -h|-help) 
    print_help
    exit 1
  ;;
  -inversions)
    nextarg=`expr $i + 1`
    eval inversions=\${${nextarg}}
    echo "inversions string is $inversions"
  ;;
  -onlyGrads)
    write_nifti=false
  ;;
  esac
  i=$[$i+1]
done





f_2dseq=$1
nii=$2


MatlabCMD=/home/inb/lconcha/fmrilab_software/myMatlab/bin/matlab
aedesPath=/home/inb/lconcha/fmrilab_software/tools/matlab/aedes


$MatlabCMD -nodisplay <<EOF
warning off
addpath(genpath('$aedesPath'))
inb_bruker_to_nii('$f_2dseq','$nii','compress', true,'doPlot',false,'inversions','$inversions','write_nii',$write_nifti)
EOF