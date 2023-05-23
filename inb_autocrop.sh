#!/bin/bash


# Help function
function help() {
		echo "
		Autocrop the SPGR images.
		
		To use: `basename $0` <spgr.mnc.gz> <spgr_cropped.mnc.gz>
		
		Luis Concha
		INB, UNAM
		August 2010
		
		"
		exit 1
}




# ------------------------
# Parsing the command line
# ------------------------
if [ "$#" -lt 2 ]; then
		echo "[ERROR] - Not enough arguments"
		help
fi
orig=$1
final=$2


isZipped=0
if [ -n "`echo ${final} | grep .gz`" ]
then
  isZipped=1
  final=${final%.gz}
fi






mincreshape -clobber -float +direction -dimsize xspace=-1 -dimsize yspace=-1 -dimsize zspace=-1 -dimorder zspace,yspace,xspace \
  $orig /tmp/crop_$$_orig.mnc
  
  
mincbet /tmp/crop_$$_orig.mnc /tmp/crop_$$ -m -n


autocrop_volume /tmp/crop_$$_mask.mnc /tmp/crop_$$_bbox.mnc 0 10
autocrop -from /tmp/crop_$$_bbox.mnc $orig $final

if [ $isZipped -eq 1 ]
then
  gzip $final
fi

rm -f /tmp/crop_{$$}*