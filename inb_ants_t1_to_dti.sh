#!/bin/bash
source `which my_do_cmd`

t1=$1
t2=$2
b0=$3
outbase=$4


tmpDir=/tmp/`random_string`
mkdir $tmpDir


fakeflag="-fake"

echo " 1. Coregister the t1 to the b0 using a non-linear transform."
my_do_cmd $fakeflag antsIntroduction.sh -d 3 -i $t1 -r $b0 -o $outbase -s MI -t SY -q 1



rm -fR $tmpDir