#!/bin/bash

matrix=$1
contrasts=$2
partial_fsf=$3

nRows=`wc -l $matrix`
nCols=`cat $matrix | awk '{print NF}' | tail -n 1`
nEV=`echo "$nCols - 1" | bc`


declare -i n
declare -i linenum


tmpdir=/tmp/matrix_$$
mkdir $tmpdir



# get the titles
titles=`head $matrix -n 1`
for ev in `seq 1 $nEV`
do
  column=`echo "$ev + 1" | bc`
  title=`echo $titles | awk -v col=$column '{print $col}'` 
  echo "set fmri(evtitle$ev) \"$title\" " | tee -a ${tmpdir}/evs
  echo "set fmri(shape$ev) 2 " | tee -a ${tmpdir}/evs
  echo "set fmri(convolve$ev) 0 " | tee -a ${tmpdir}/evs
  echo "set fmri(convolve_phase$ev) 0 " | tee -a ${tmpdir}/evs
  echo "set fmri(tempfilt_yn$ev) 0 " | tee -a ${tmpdir}/evs
  echo "set fmri(deriv_yn$ev) 0 " | tee -a ${tmpdir}/evs
  echo "set fmri(custom$ev) \"dummy\" " | tee -a ${tmpdir}/evs
  for ev_b in `seq 0 $nEV`
  do
    echo "set fmri(ortho$ev.$ev_b) 0 " >> ${tmpdir}/evs
  done
  echo "" >>  ${tmpdir}/evs
done




n=1
linenum=0
cat $matrix | while read line
do
  linenum=$[$linenum+1]
  if [ $linenum -eq 1 ]
  then
    continue
  fi
  
  myprogress $n $nRows


  f=`echo $line | awk '{print $1}'`
  echo "set feat_files($n) \"$f\" " >> ${tmpdir}/inputs
  

  for ev in `seq 1 $nEV`
  do
    column=`echo "$ev + 1" | bc`
    value=`echo $line | awk -v col=$column '{print $col}'` 
    echo "# Higher-level EV value for EV $ev and input $n" >> ${tmpdir}/evs
    echo "set fmri(evg${ev}.$n) $value" >> ${tmpdir}/evs
    echo "" >>  ${tmpdir}/evs
  done
  n=$[$n+1]
done


n=1
nCols=`cat $contrasts | awk '{print NF}' | tail -n 1`
nCons=`echo "$nCols - 1" | bc`
cat $contrasts | while read line
do
  contrastName=`echo $line | awk '{print $1}'`
  echo "# Display images for contrast_real $n" >> ${tmpdir}/contrasts
  echo "set fmri(conpic_real.$n) 1" >> ${tmpdir}/contrasts
  echo "" >>  ${tmpdir}/contrasts
  echo "# Title for contrast_real $n" >> ${tmpdir}/contrasts
  echo "set fmri(conname_real.$n) \"$contrastName\" " >>  ${tmpdir}/contrasts
  echo ""  >> ${tmpdir}/contrasts

  echo "# Set contrast $n vector"  >> ${tmpdir}/contrasts
  for c in `seq 1 $nCons`
  do
    column=`echo "$c + 1" | bc`
    value=`echo $line | awk -v col=$column '{print $col}'` 
    echo "set fmri(con_real$n.$c) $value" >> ${tmpdir}/contrasts
  done
  echo ""  >> ${tmpdir}/contrasts
  n=$[$n+1]
done






cat ${tmpdir}/inputs ${tmpdir}/evs ${tmpdir}/contrasts > $partial_fsf

rm -fR $tmpdir
