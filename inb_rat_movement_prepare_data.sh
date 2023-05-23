#!/bin/bash

infile=$1
rat=$2
outfile=$3



help() {
echo "

Usage: `basename $0` infile.csv rat outfile.csv

Example:

`basename $0` 20171211.csv rata9 20171211_simplified.csv 



LU15 (0N(H4
INB, UNAM
July 2017
lconcha@unam.mx

"
}


if [ "$#" -lt 3 ]
then
  echo "  [ERROR]. Insufficient arguments."
  help
  exit 2
fi


n=`grep $rat $infile | wc -l`
if [ $n -eq 0 ]
then
  echolor red "ERROR: Cannot find $rat in file $infile . Perhaps your rat ID is incorrect?"
  exit 2
else
  echolor green "INFO: There are $n data points for rat $rat"
fi


grep $rat $infile | awk -F,  'BEGIN{OFS=",";}{print $15,$16,$17}'  | sed s/s//g | sed s/\(//g | sed s/\)//g > $outfile

echolor green "Displaying the last few lines of the newly created file $outfile"
tail $outfile

echolor green "Done. Now, in matlab you can visualize these data by invoking inb_rat_movement('$outfile');"
