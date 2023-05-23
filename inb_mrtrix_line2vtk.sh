#!/bin/bash

line=$1
vtk=$2

nPoints=`wc -l $line | awk '{print $1}'`


echo "# vtk DataFile Version 1.0" > $vtk
echo "one line" >> $vtk
echo "ASCII" >> $vtk
echo "DATASET POLYDATA" >> $vtk

echo "POINTS $nPoints float" >> $vtk
cat $line >> $vtk


nIdx=$[$nPoints+1]
minusOne=$[$nPoints-1]
echo "LINES 1 $nIdx" >> $vtk
printf "%d " $nPoints >> $vtk

for idx in `seq 0 $minusOne`
do
 printf "%d " $idx >> $vtk
done