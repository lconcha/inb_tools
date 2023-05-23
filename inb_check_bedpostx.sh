#!/bin/bash


bpxDir=$1


checkDiffSlices=0
BadSlices=0

allGood=1
if [ ! -f $bpxDir/dyads1.nii.gz ]
then
	echo "dyads1 does not exist"
	checkDiffSlices=1
fi	

if [ ! -f $bpxDir/dyads2.nii.gz ]
then
	echo "dyads2 does not exist"
	checkDiffSlices=1
fi	



if [ -f ${bpxDir}/badSlices.log ]
then
	rm -f ${bpxDir}/badSlices.log
fi



if [ $checkDiffSlices -eq 1 ]
then
   echo "Something is wrong. Let's check the diff_slices directory"
   if [	! -d $bpxDir/diff_slices ]
   then
   	echo "ERROR: There is no diff_slices directory! I cannot do anything for you."
   	exit 1
   else
   	find $bpxDir -name data_slice_* -type d | while read d
   	do 
   		if [ ! -f $d/dyads1.nii.gz ]
   		then 
   			echo "  ERROR: $d" | tee -a ${bpxDir}/badSlices.log
   			allGood=0
   			BadSlices=1 
   		fi
   	done
   fi
fi


if [ -f ${bpxDir}/badSlices.log ]
then
	echo "ERROR: There are bad slices."
	allGood=0
fi

if [ $allGood -eq 1 ]
then
	echo "Everything seems fine with $bpxDir."
	if [ $checkDiffSlices -eq 1 ]
	then
		echo "But the postproc did not run. 
		Run bedpostx_postproc.sh ${bpxDir%.bedpostX} and you should be OK."
	fi
fi




