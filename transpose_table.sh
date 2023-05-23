#!/bin/bash

print_help() {
  echo "
  Transpose a text file from rows to columns or the other way.
  
  Luis Concha
  INB
  July 2010
  
  taken from here: http://stackoverflow.com/questions/1729824/transpose-a-file-in-bash
  
  use:
  
  `basename $0` fileToTranspose.txt
  
  
  Use the > operand to pipe the results to a new text file.
  
"
}


if [ $# -lt 1 ] 
then
	print_help
	exit 1
fi



declare -a array=( )                      # we build a 1-D-array

read -a line < "$1"                       # read the headline

COLS=${#line[@]}                          # save number of columns

index=0
while read -a line ; do
    for (( COUNTER=0; COUNTER<${#line[@]}; COUNTER++ )); do
        array[$index]=${line[$COUNTER]}
        ((index++))
    done
done < "$1"

for (( ROW = 0; ROW < COLS; ROW++ )); do
  for (( COUNTER = ROW; COUNTER < ${#array[@]}; COUNTER += COLS )); do
    printf "%s\t" ${array[$COUNTER]}
  done
  printf "\n" 
done
