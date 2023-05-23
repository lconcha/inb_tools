#!/bin/bash
source `which my_do_cmd`
export FSLOUTPUTTYPE=NIFTI
# fakeflag="-fake"
fakeflag=""

DWI=$1
mask=$2
bet_options=$3



print_help()
{
  
 echo "

  `basename $0` <dwi.mif> <output_mask.mif> [bet_options]




LU15 (0N(H4
lconcha@unam.mx
INB, UNAM
August, 2017
"
}



if [ $# -lt 2 ] 
then
	echo " ERROR: Need more arguments..."
	print_help
	exit 2
fi


my_do_cmd mrconvert $DWI /tmp/bet_$$.nii 
my_do_cmd bet  /tmp/bet_$$.nii  /tmp/bet_$$ -m -n $bet_options
my_do_cmd mrconvert /tmp/bet_$$_mask.nii $mask
rm -f /tmp/bet_$$*
