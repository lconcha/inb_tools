#!/bin/bash


matsdir=$1
ecclog=$2



for f in ${matsdir}/*_ec.mat
  do
    echo "processing ${f%.mat}" >> $ecclog
    echo "" >> $ecclog
    echo "Final result:" >> $ecclog
    cat $f >> $ecclog
    echo "" >> $ecclog
  done
