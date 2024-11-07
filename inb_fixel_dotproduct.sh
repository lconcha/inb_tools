#!/bin/bash
source `which my_do_cmd`


function check_ext () {
    f=$1
    #echo "Checking extension for $f"
    extension="${f##*.}"
    case $extension in
    "nii")
        isOK=1
    ;;
    "gz")
        isOK=1
    ;;
    "mif")
        isOK=1
    ;;
    *)
        echolor red "[ERROR] Unrecognized file extension for file $f"
        exit 2
    ;;
    esac
}


is_static_vector=0
while getopts f:g:v:o: flag
do
    case "${flag}" in
        f) input_file=${OPTARG}
           check_ext $input_file
           fixel0=$input_file;;           
        g) input_file=${OPTARG}
           check_ext $input_file
           fixel1=$input_file;;
        v) is_static_vector=1
           fixel1=${OPTARG}
           echo "Provided static vector $fixel1";;
        o) fixeldotproduct=${OPTARG};;
    esac
done






tmpDir=$(mktemp -d)

# Fix the strides so that we do not have problems when loading into matlab
my_do_cmd mrconvert -strides 1,2,3,4 $fixel0 ${tmpDir}/fixel0.mif
fixel0=${tmpDir}/fixel0.mif
if [ $is_static_vector -eq 0 ]
then
  my_do_cmd mrconvert -strides 1,2,3,4 $fixel1 ${tmpDir}/fixel1.mif
  fixel1=${tmpDir}/fixel1.mif
fi


# build matlab command
matlabJob=${tmpDir}/matlabjob.m
if [ $is_static_vector -eq 0 ]
then
  echo "addpath('$(dirname $0)/matlab');" > $matlabJob
  echo "inb_fixel_dotproduct('${fixel0}','${fixel1}','${fixeldotproduct}');" >> $matlabJob
  echo "quit" >> $matlabJob
else
  sfixel1="[${fixel1//,/ }]"
  echo "addpath('$(dirname $0)/matlab');" > $matlabJob
  echo "inb_fixel_dotproduct('${fixel0}',$sfixel1,'${fixeldotproduct}');" >> $matlabJob
  echo "quit" >> $matlabJob
fi


echo ""
echo "---- <matlab job> --------"
cat $matlabJob
echo "---- </matlab job> -------"
echo ""

matlab -nodisplay < $matlabJob



rm -fR $tmpDir