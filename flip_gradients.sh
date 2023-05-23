#!/bin/bash

bvecsIN=$1
bvecsOUT=$2


print_help()
{
  echo ""
  echo "`basename $0` <bvecsIN> <bvecsOUT> [Options]"
  echo ""
  echo "Options:" 
  echo "  -flip_x" 
  echo "  -flip_y" 
  echo "  -flip_z" 
  echo "" 
  echo "Luis Concha - INB"
  echo "Julio 2010"
  echo ""

}

if [ $# -lt 2 ] 
then
    echo "At least 2 arguments are required."
    print_help
    exit 2
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




x=`head -n 1 $bvecsIN | tail -n 1`
y=`head -n 2 $bvecsIN | tail -n 1`
z=`head -n 3 $bvecsIN | tail -n 1`


xx=$x
yy=$y
zz=$z
for arg in "$@"
do

	case "$arg" in
	   -flip_x)
		echo "Will flip x component"
		xx=""
		for v in $x
		do
		  vv=`echo "$v * -1" | bc -l`
		  xx="$xx $vv"
		done
		;;
	   -flip_y)
		echo "Will flip y component"
		yy=""
		for v in $y
		do
		  vv=`echo "$v * -1" | bc -l`
		  yy="$yy $vv"
		done
		;;
	   -flip_z)
		echo "Will flip z component"
		zz=""
		for v in $z
		do
		  vv=`echo "$v * -1" | bc -l`
		  zz="$zz $vv"
		done
		;;
	esac
	index=$[$index+1]
done

echo $xx > $bvecsOUT
echo $yy >> $bvecsOUT
echo $zz >> $bvecsOUT



