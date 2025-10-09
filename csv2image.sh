#!/bin/bash

csv=$1
png=$2
size=$3


if [ -z "$size" ]; then
  size="800,600"
fi      



if [ -z $png ]; then
  gnuplot -p -e "set datafile separator ','; set view map; splot '$csv' matrix with image"
else
  gnuplot -e \
    "set terminal png size $size; set output '$png'; set datafile separator ','; set view map; splot '$csv' matrix with image"
fi