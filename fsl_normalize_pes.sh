#!/bin/bash
source ~/noelsoft/BashTools/my_do_cmd

FEATdir=$1
OUTdir=$2
model=$3

if [ -d $OUTdir ]
then
	echo .
else
	mkdir -p $OUTdir
fi

FSLOUTPUTTYPE=NIFTI


ref=$model
xfm=${FEATdir}/reg/example_func2standard.mat

#pe=${FEATdir}/stats/pe1.nii.gz

for pe in ${FEATdir}/stats/pe*.nii.gz
do
	pefname=`basename $pe`
	outvol=${OUTdir}/`remove_ext ${pefname}`
	my_do_cmd flirt -in $pe -ref $ref -applyxfm -init $xfm -out $outvol
done
