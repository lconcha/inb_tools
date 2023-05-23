#!/bin/bash
source `which my_do_cmd`

IN=$1
OUT=$2
badvols=$3




print_help()
{
  
 echo "

  `basename $0` <IN.mif> <OUT.mif> <bad_indices>

Remove specific volumes from a 4D data set. 
Can be useful to remove frames with artifacts from DWI or fMRI data sets.

Specify bad_indices as a comma-separated list (no spaces allowed!).

Example: 
`basename $0` dwifull.mif dwi_clean.mif 3,4,78

(will remove frames 3, 4 and 78).

Please note that frame indices start at zero.

LU15 (0N(H4
lconcha@unam.mx
INB, UNAM
August, 2017
"
}



if [ $# -lt 2 ] 
then
	echo " ERROR: Need more arguments..."
	print_help
	exit 2
fi








echo "  Input  file: $IN"
echo "  Output file: $OUT"
echo "  Volumes to remove: $badvols"



nVolsIN=`mrinfo -size $IN | awk '{print $4}'`
echo "  Input file has $nVolsIN volumes"



badvolslist=`echo $badvols | tr , " "`

vol_indices=(`seq -s" " 0 $(($nVolsIN-1))`)
## Remove array elements
for idx in $badvolslist
do
  unset vol_indices[$idx]
done

goodvols=`echo ${vol_indices[@]} | tr " " ,`


my_do_cmd mrconvert -coord 3 $goodvols $IN $OUT
nVolsOUT=`mrinfo -size $OUT | awk '{print $4}'`
echo "  Output file has $nVolsOUT volumes"




