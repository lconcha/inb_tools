#!/bin/bash
source `which my_do_cmd`

folder=$1
outbase=$2


function help() {
echo "
`basename $0` <directory> <outbase>

Go through a paravision 6 data structure and convert all images found within.
Uses mrtrix3's function convert_bruker.

Outputs a bunch of .mih files that point to the 2dseq data. These files are just headers,
that point to the actual data in the 2dseq folder (go a head, open up a .mih file with a
text editor and see what I mean).

This is very useful for reviewing a session of imaging, then deciding which files you really need.

Luis Concha
Nov, 2015
INB, UNAM

"
}



if [ "$#" -lt 2 ]; then
  echo "[ERROR] - Not enough arguments"
  help
  exit 2
fi


declare -i i
i=1
verbose=1
for arg in "$@"
do
  case "$arg" in
  -h|-help)
    help
    exit 1
  ;;
  esac
  i=$[$i+1]
done




if [ -z `command -v convert_bruker` ]
then
  echo ""
  echo "ERROR: cannot find command convert_bruker"
  echo "Please use the newest branch of mrtrix3."
  echo "To set it up, type:"
  exit 2
fi



for line in `find $folder -name 2dseq | grep pdata/1/`
do
  n=`basename ${line%/pdata/1/2dseq}`
  seq_num=`zeropad $n 3`
  echo $seq_num
  acqp=${line%/pdata/1/2dseq}/acqp
  ls $acqp
  protocol=`sed -n '/\#\#\$ACQ_scan_name=/,/\#\#/p' $acqp | \
            head -n-1 | \
            tail --lines=+2 | \
            sed 's/<//g' | sed 's/>//g' | sed 's/ /_/g' | sed 's/(//g' | sed 's/)//g'`
            echolor cyan "$protocol"
  my_do_cmd convert_bruker $line ${outbase}_${seq_num}_${protocol}.mih
   echo ""
done

echo ==============================================

ls ${outbase}*.mih
