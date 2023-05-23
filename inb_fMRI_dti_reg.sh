#!/bin/bash
source `which my_do_cmd` 
fakeflag=""

tmpDir=/tmp/`random_string` 
mkdir $tmpDir



print_help()

{
echo "
`basename $0` <dti.nii.gz> <featDir> <outbase>

Registers the b0 to the contents of a feat directory, including standard.

Luis Concha
INB
2012
"

}

if [ $# -lt 3 ] 
then
	echo " ERROR: Need more arguments..."
	print_help
	exit 1
fi





dti=$1
featDir=$2
outbase=$3

example_func=${featDir}/example_func.nii.gz
xfm_func2std=${featDir}/reg/example_func2standard.mat
fsf=${featDir}/design.fsf
df=12; #Degrees of freedom for flirt


# Sanity check
if [ ! -f $example_func ]; then
  echo "FATAL ERROR: Cannot find $example_func" 
  exit 2
fi
if [ ! -f $dti ]; then
  echo "FATAL ERROR: Cannot find $dti" 
  exit 2
fi
if [ ! -f $xfm_func2std ]; then
  echo "FATAL ERROR: Cannot find $xfm_func2std" 
  exit 2
fi
if [ ! -f $fsf ]; then
  echo "FATAL ERROR: Cannot find $fsf" 
  exit 2
fi



# Extract a b=0
b0=${tmpDir}/b0.nii.gz
my_do_cmd $fakeflag fslroi $dti $b0 0 1


# bet the b0 and the example_func
bet_example_func=${outbase}_bet_example_func.nii.gz
bet_b0=${outbase}_bet_b0.nii.gz
my_do_cmd $fakeflag bet $example_func $bet_example_func  -f 0.25
my_do_cmd $fakeflag bet $b0 $bet_b0 -f 0.15


# flirt the b0 to the example_func 
my_do_cmd $fakeflag flirt \
  -ref $bet_example_func \
  -in $bet_b0 \
  -omat ${outbase}_b0_to_bold.mat \
  -out ${outbase}_b0_to_bold.nii.gz \
  -cost corratio \
  -dof $df \
  -searchrx -90 90 -searchry -90 90 -searchrz -90 90 \
  -interp trilinear



# concatenate the transformations b0 to example_func to std
my_do_cmd $fakeflag convert_xfm \
  -omat ${outbase}_b0_to_standard.mat \
  -concat \
  $xfm_func2std ${outbase}_b0_to_bold.mat

# invert the concatenated transformation
my_do_cmd $fakeflag convert_xfm \
  -omat ${outbase}_standard_to_b0.mat \
  -inverse \
  ${outbase}_b0_to_standard.mat

# Apply transformation t0 b0 to go to standard
my_do_cmd $fakeflag flirt \
  -in $bet_b0 \
  -ref ${featDir}/reg/standard.nii.gz \
  -applyxfm -init ${outbase}_b0_to_standard.mat \
  -out ${outbase}_b0_to_standard.nii.gz


# b0 to bold to T1
my_do_cmd $fakeflag convert_xfm \
  -omat ${outbase}_b0_to_highres.mat \
  -concat \
  ${featDir}/reg/example_func2highres.mat \
  ${outbase}_b0_to_bold.mat

# T1 to b0 (via inversion)
my_do_cmd $fakeflag convert_xfm \
  -omat ${outbase}_highres_to_b0.mat \
  -inverse \
  ${outbase}_b0_to_highres.mat


# Some quality check
atlasUsed=`grep " fmri(regstandard)"  $fsf | awk -F\" '{print $2}'`
my_do_cmd $fakeflag slicer ${outbase}_b0_to_standard.nii.gz $atlasUsed -a ${outbase}_b0_to_standard.png
my_do_cmd $fakeflag slicer ${outbase}_b0_to_bold.nii.gz $bet_example_func -a ${outbase}_b0_to_bold.png

# Find out which standard image was used in the FEAT
echo "Finished transforming:
  FROM ==> dti data ($bet_b0)
  TO   ==> standard space ($atlasUsed)

to check the quality of the registration, run:
fslview $atlasUsed ${outbase}_b0_to_standard.nii.gz
fslview $bet_example_func ${outbase}_b0_to_bold.nii.gz
" 


rm -fR $tmpDir

