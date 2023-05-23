#!/bin/bash

BVECS=$1
MAT=$2
rBVECS=$3

if [ -f $rBVECS ]
then
	echo "Overwriting $rBVECS"
        rm -f $rBVECS
fi

Xs=$(cat $BVECS | head -1 | tail -1)
Ys=$(cat $BVECS | head -2 | tail -1)
Zs=$(cat $BVECS | head -3 | tail -1)


VOLUMES=$(cat $BVECS | head -1 | tail -1 | wc -w)



echo "Rotating $BVECS into $rBVECS ..."
i=1
while [ $i -le $VOLUMES ] ; do
	#echo $MAT
        printf '%d ' `echo $VOLUMES - $i | bc`
	output=$(avscale --allparams ${MAT} | head -2 | tail -1)
	m11=$(echo $output | cut -d " " -f 1)
	m12=$(echo $output | cut -d " " -f 2)
	m13=$(echo $output | cut -d " " -f 3)
	m11=$(printf "%1.7f" $m11)
	m12=$(printf "%1.7f" $m12)
	m13=$(printf "%1.7f" $m13)

	output=$(avscale --allparams ${MAT} | head -3 | tail -1)
	m21=$(echo $output | cut -d " " -f 1)
	m22=$(echo $output | cut -d " " -f 2)
	m23=$(echo $output | cut -d " " -f 3)
	m21=$(printf "%1.7f" $m21)
	m22=$(printf "%1.7f" $m22)
	m23=$(printf "%1.7f" $m23)

	output=$(avscale --allparams ${MAT} | head -4 | tail -1)
	m31=$(echo $output | cut -d " " -f 1)
	m32=$(echo $output | cut -d " " -f 2)
	m33=$(echo $output | cut -d " " -f 3)
	m31=$(printf "%1.7f" $m31)
	m32=$(printf "%1.7f" $m32)
	m33=$(printf "%1.7f" $m33)

	X=$(echo $Xs | cut -d " " -f "$i")
	Y=$(echo $Ys | cut -d " " -f "$i")
	Z=$(echo $Zs | cut -d " " -f "$i")
	X=$(printf "%1.7f" $X)
	Y=$(printf "%1.7f" $Y)
	Z=$(printf "%1.7f" $Z)

	rX=$(echo "scale=7;  ($m11 * $X) + ($m12 * $Y) + ($m13 * $Z)" | bc -l);
	rY=$(echo "scale=7;  ($m21 * $X) + ($m22 * $Y) + ($m23 * $Z)" | bc -l);
	rZ=$(echo "scale=7;  ($m31 * $X) + ($m32 * $Y) + ($m33 * $Z)" | bc -l);

	rX=$(printf "%1.7f" $rX)
	rY=$(printf "%1.7f" $rY)
	rZ=$(printf "%1.7f" $rZ)

#	echo $rX" "$rY" "$rZ;

	rXs=${rXs}${rX}" ";
	rYs=${rYs}${rY}" ";
	rZs=${rZs}${rZ}" ";

	i=$(echo "$i + 1" | bc) ;
done
printf '\n'

echo "$rXs" >> $rBVECS;
echo "$rYs" >> $rBVECS;
echo "$rZs" >> $rBVECS;
#
####################################################################
