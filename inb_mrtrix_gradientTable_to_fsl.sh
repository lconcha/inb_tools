#!/bin/bash

gTable=$1
bval=$2
bvec=$3


transpose_table.sh $gTable | head -n 3 > $bvec
transpose_table.sh $gTable | tail -n 1 > $bval
