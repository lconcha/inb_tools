#!/bin/bash

nodif=$1
dif=$2
bval=$3
adc=$4

print_help()
{
    echo "
`basename $0` <nodif.nii.gz> <dif.nii.gz> <bval> <adc.nii.gz>

Luis Concha
INB 2012
"
}




if [ $# -lt 4 ] 
then
	echo " ERROR: Need more arguments..."
	print_help
	exit 1
fi


ratio=tmp_$$_ratio.nii.gz
logratio=tmp_$$_logratio.nii.gz

fslmaths -dt double $dif -div $nodif $ratio -odt double
fslmaths -dt double $ratio -log $logratio -odt double
fslmaths -dt double $logratio -div -${bval} $adc -odt double

rm tmp_$$*