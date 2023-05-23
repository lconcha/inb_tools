#!/bin/bash

print_help()
{
  echo  "
`basename $0` <bvecsIN> <bvecsOUT>
Luis Concha - INB
Enero 2011
"
}


if [ $# -lt 2 ] 
then
  echo "  ERROR: Need more arguments..."
  print_help
  exit 1
fi




bvecsIN=$1
bvecsOUT=$2

transpose_table.sh $bvecsIN > /tmp/bvecsIN
bvecsIN=/tmp/bvecsIN




x=`head -n 1 $bvecsIN | tail -n 1`
y=`head -n 2 $bvecsIN | tail -n 1`
z=`head -n 3 $bvecsIN | tail -n 1`
b=`head -n 4 $bvecsIN | tail -n 1`


xx=$x
yy=$y
zz=$z
declare -i index
index=1
for arg in "$@"
do

	case "$arg" in
		-h|-help) 
		print_help
		exit 1
		;;
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

echo $xx >  /tmp/bvecsOUT
echo $yy >> /tmp/bvecsOUT
echo $zz >> /tmp/bvecsOUT
echo $b  >> /tmp/bvecsOUT

transpose_table.sh /tmp/bvecsOUT > /tmp/bvecsOUT2
awk '{printf "%1.6f\t%1.6f\t%1.6f\t%d\n",$1,$2,$3,$4}' /tmp/bvecsOUT2 > $bvecsOUT
rm /tmp/bvecsIN /tmp/bvecsOUT /tmp/bvecsOUT2


