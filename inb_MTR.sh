#!/bin/bash


# Help function
function help() {
		echo "
		Generate a Magnetization transfer ratio map.
		
		To use: `basename $0` <spgr.nii.gz> <spgr_magT.nii.gz> <MTR.nii.gz>
		
		Luis Concha
		INB, UNAM
		August 2010
		
		"
		exit 1
}




# ------------------------
# Parsing the command line
# ------------------------
if [ "$#" -lt 3 ]; then
		echo "[ERROR] - Not enough arguments"
		help
fi
S0=$1
magT=$2
MTR=$3




echo "fslmaths $S0 -sub $magT tmp_$$_sub.nii.gz"
fslmaths $S0 -sub $magT tmp_$$_sub.nii.gz

echo "fslmaths tmp_$$_sub.nii.gz -div $S0 $MTR -odt double"
fslmaths tmp_$$_sub.nii.gz -div $S0 $MTR -odt double

rm -f tmp_$$_sub.nii.gz

