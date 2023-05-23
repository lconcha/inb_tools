#!/bin/bash
source `which my_do_cmd` 

print_help()
{
  echo "
  `basename $0` <dti.mif> <dti_corr.mif> [-options]

  Options:
   -help
   -clobber

  Luis Concha
  INB
  Feb 2011			
"
}


if [ $# -lt 2 ] 
then
  echo "  ERROR: Need more arguments..."
  print_help
  exit 1
fi


declare -i i
i=1
clobber=0
for arg in "$@"
do

  case "$arg" in
  -h|-help) 
    print_help
    exit 1
  ;;
  -clobber)
    clobber=1
  ;;
  esac
  i=$[$i+1]
done




mif=$1
mifEC=$2

mrinfo -export_grad_fsl /tmp/$$.bvec /tmp/$$.bval $mif
bvecIN=/tmp/$$.bvec
bvecOUT=/tmp/$$_rotated.bvec


if [ -f $mifEC -a $clobber -eq 0 ]
then
  echo "File $mifEC exists. Use -clobber to overwrite. Bye".
  exit 1
fi


FSLOUTPUTTYPE=NIFTI
my_do_cmd mrconvert $mif ${mif%.mif}.nii
my_do_cmd eddy_correct ${mif%.mif}.nii ${mif%.mif}_ec.nii 0
ecclog=${mif%.mif}_ec.ecclog




my_do_cmd rotbvecs $bvecIN $bvecOUT $ecclog
my_do_cmd mrconvert -fslgrad $bvecOUT /tmp/$$.bval ${mif%.mif}_ec.nii $mifEC


rm $tmpfile $bvecIN $bvecOUT $ecclog ${mif%.mif}.nii ${mif%.mif}_ec.nii
