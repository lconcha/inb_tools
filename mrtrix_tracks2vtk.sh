#!/bin/bash




print_help()
{
  echo "
  `basename $0` <tracks.tck> <tracks.vtk>

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



## Parse arguments
tck=$1
vtk=$2



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




tmpDir=/tmp/$$_tck2vtk
mkdir $tmpDir


track_info -ascii ${tmpDir}/base $tck
mrtrix_lines2vtk.sh ${tmpDir} $vtk 

rm -fR $tmpDir
