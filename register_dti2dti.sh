#!/bin/bash

source=$1
target=$2
registered=$3
bvec_source=$4
bvec_registered=$5



print_help()
{
  echo "
  `basename $0` <source.nii.gz> <targetf> <registered.nii.gz> [bvec_source] [bvec_registered] [-Options]

  Options:
  
  -notDTI
  -clobber
  -target_b0_index <int>
  -source_b0_index <int>

  Luis Concha
  INB
  Feb 2011			
"
}


do_cmd() 
{
   local l_command=""
   local l_sep=""
   local l_index=1
   while [ ${l_index} -le $# ]; do
   eval arg=\${$l_index}
   l_command="${l_command}${l_sep}${arg}"
   l_sep=" "
   l_index=$[${l_index}+1]
   done
   echo " --> ${log_header} ${l_command}"
   $l_command
}



if [ $# -lt 3 ] 
then
  echo "  ERROR: Need more arguments..."
  print_help
  exit 1
fi

isDTI=1
if [ $# -lt 5 ] 
then
  echo "  This is not a DTI file (or gradient info was not provided)"
  isDTI=0
fi




target_b0_index=0
source_b0_index=0
clobber=0


declare -i index
declare -i nextArg
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
	   -notDTI)
		isDTI=0
		;;
	   -target_b0_index)
		nextArg=${index}+2
		eval target_b0_index=\$$nextArg
		;;
	   -source_b0_index)
		nextArg=${index}+2
		eval source_b0_index=\$$nextArg
		;;
	esac
	index=$[$index+1]
done

tmpDir=/tmp/dti2dti_$$
mkdir -p $tmpDir

mat=${tmpDir}/xfm.mat
do_cmd fslroi $source ${tmpDir}/b0_source $source_b0_index 1
do_cmd fslroi $target ${tmpDir}/b0_target $target_b0_index 1
do_cmd flirt -in ${tmpDir}/b0_source \
             -ref ${tmpDir}/b0_target \
             -omat $mat \
             -nosearch \
             -dof 12

do_cmd flirt -in $source \
             -ref $target \
             -applyxfm -init $mat \
             -out $registered

if [ $isDTI -eq 1 ]
then
  do_cmd rotbvecs_singleXFM.sh $bvec_source $mat $bvec_registered
fi

rm -fR $tmpDir