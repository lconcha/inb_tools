#!/bin/bash


aparc=$1
simple=$2


echo "aparc_simplify('$aparc','$simple');" >> /tmp/$$jobfile


matlab -nodisplay $cmd < /tmp/$$jobfile

rm /tmp/$$jobfile




