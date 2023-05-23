#!/bin/bash

cat_list=$1
stims=$2
outbase=$3


my_list=`awk '{print $2}' $cat_list | xargs echo`

# for ctg in $my_list
# do
#   grep $ctg $stims | awk '{print $1,$2,1}' > ${outbase}_${ctg}.times
# done




for ctg in $my_list
do
  : > ${outbase}_${ctg}.txt
  cat $stims | while read line
  do
    thisCat=`echo $line | awk '{print $4}'`
    if [[ "$thisCat" == "$ctg" ]]
    then
      echo 1 >> ${outbase}_${ctg}.txt
    else
      echo 0 >> ${outbase}_${ctg}.txt
    fi
  done
done



