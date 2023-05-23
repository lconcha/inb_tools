#!/bin/bash
# https://www.jiscmail.ac.uk/cgi-bin/webadmin?A2=fsl;8e169ec.1507



print_help()
{
  
 echo "

  `basename $0` <in.mat> <out.mat>


Turns a .mat transformation matrix from hexadecimal to decimal notation.
Because of this: 
https://www.jiscmail.ac.uk/cgi-bin/webadmin?A2=fsl;8e169ec.1507

For example applyWarp sometime files with .mat files in hexadecimal.


LU15 (0N(H4
INB, UNAM
Oct 2020
lconcha@unam.mx
"
}

if [ $# -lt 2 ] 
then
	echo " ERROR: Need more arguments..."
	print_help
	exit 1
fi



for arg in "$@"
do
  case "$arg" in
  -h|-help) 
    print_help
    exit 1
  ;;
esac
done

# Read from specified file, or from standard input
infile=$1
outfile=$2


if [ -f $outfile ]
then
  echolor red "ERROR: File exists: $outfile"
  exit 2
fi


while read line; do
    for number in $line; do
        printf "%f " "$number" >> $outfile
    done
    echo >> $outfile
done < $infile
