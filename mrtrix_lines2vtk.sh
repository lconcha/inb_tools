#!/bin/bash




print_help()
{
  echo "
  `basename $0` <linesDir> <lines.vtk>

  Options:
  

  Luis Concha
  INB, UNAM
  April 2011			
"
}


if [ $# -lt 2 ] 
then
  echo " ERROR: Need more arguments..."
  print_help
  exit 1
fi



declare -i i
i=1
skip=1
for arg in "$@"
do
  case "$arg" in
    -h|-help) 
      print_help
      exit 1
    ;;
    -skip)
      nextarg=`expr $i + 1`
      eval skip=\${${nextarg}}
    ;;
    esac
    i=$[$i+1]
done




## Parse arguments
linesDir=$1
vtk=$2



## Do not overwrite
if [ -f $vtk ]
then
  echo "File exists and not overwriting: $vtk"
  exit 1
fi




## Make a temp directory and some files we will need
tmpDir=/tmp/$$_lines2vtk
mkdir $tmpDir
coords=${tmpDir}/coords.txt



# Remove any lines we will skip

# nLines=`find $linesDir -type f | wc -l`
# if [ $skip -gt 1 ]
# then
#     echo Keeping only every $skip line
#     mkdir ${tmpDir}/skipped
#     for l in `seq 1 $skip $nLines`
#     do
# 	echo cp ${linesDir}/base_`zeropad $l 6`.txt ${tmpDir}/skipped/base_`zeropad $l 6`.txt
# 	cp ${linesDir}/base_`zeropad $l 6`.txt ${tmpDir}/skipped/base_`zeropad $l 6`.txt
#     done
#    linesDir=${tmpDir}/skipped
# fi




## Get all the coordinates from all lines
cat ${linesDir}/*.txt > $coords
nPoints=`wc -l $coords | awk '{print $1}'`







## Start writing the vtk file
echo "# vtk DataFile Version 1.0" > $vtk
echo "many lines" >> $vtk
echo "ASCII" >> $vtk
echo "DATASET POLYDATA" >> $vtk
echo "POINTS $nPoints float" >> $vtk
cat $coords >> $vtk







## Now, line by line, we set the indices.
echo "find ${linesDir}/ -type f | wc -l"
nLines=`find ${linesDir}/ -type f | wc -l`

# let's see how much we should write to stdout
if [ $nLines -lt 100 ]
then
    modulator=1
elif [ $nLines -lt 1000 ]
then
   modulator=10
else
   modulator=100
fi

# initialize the for loop
nIdx=$[$nPoints+$nLines]
seed=0
echo "LINES $nLines $nIdx" >> $vtk
linenum=0
myprogress -init "Writing to $vtk ..."

# and go!
for f in ${linesDir}/*.txt
do
  modulus=$[$linenum%$modulator]
  if [ $modulus -eq 0 ]
  then
    myprogress $linenum $nLines
  fi
  nLinePoints=`wc -l $f | awk '{print $1}'`
  printf "%d " $nLinePoints >> $vtk
  lineEnd=$[$seed+$nLinePoints-1]
  seq --separator=" " $seed $lineEnd >> $vtk
  seed=$[$lineEnd+1]
 
  linenum=$[$linenum+1]
done
myprogress -end "Finished writing $vtk"








## Clean up
rm -fR $tmpDir