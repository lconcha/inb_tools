#!/bin/bash

source `which my_do_cmd`



print_help()
{
  echo "
  `basename $0` <dtiIN> <dtiOUT> <bvecsIN> <bvecsOUT>

  dtiIN and OUT, I do not care if you use .gz or not.

  Luis Concha
  INB, UNAM
  April 2011			
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
skip=1
for arg in "$@"
do
  case "$arg" in
    -h|-help) 
      print_help
      exit 1
    esac
    i=$[$i+1]
done





dtiIN=$1
dtiOUT=$2
bvecsIN=$3
bvecsOUT=$4



#echo eddy_correct $dtiIN $dtiOUT 0
my_do_cmd  eddy_correct $dtiIN $dtiOUT 0

#echo rotbvecs $bvecsIN $bvecsOUT ${dtiOUT%.nii.gz}.ecclog
my_do_cmd  rotbvecs $bvecsIN $bvecsOUT ${dtiOUT%.nii.gz}.ecclog

