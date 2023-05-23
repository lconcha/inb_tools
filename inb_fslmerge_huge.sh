#!/bin/bash

FSLOUTPUTTYPE=NIFTI
source `which my_do_cmd`

flist=$1
OUTFILE=$2

split -l 100 $flist tmplist_


nLists=`ls tmplist_* | wc -l`

echo "There are $nLists lists"


for f in tmplist_*
do
  suffix=${f#*_}
  echo "Merging $suffix"
  my_do_cmd fslmerge -t ${im}_${suffix} `cat $f`
done


echo "Merging the temporary merged files"
my_do_cmd fslmerge -t $OUTFILE ${im}_*


sleep 2

rm tmplist_*

