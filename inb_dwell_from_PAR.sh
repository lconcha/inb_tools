#!/bin/bash

PAR=$1


function help() {
echo "
`basename $0` <PAR> [-quiet]

Calculate the dwell time of an EPI sequence, from the parameters
inside a .PAR file.

dwell = (1000 * wfs) / (FreqOffset * (etl+1) )
  where wfs        = Water Fat Shirt
        FreqOffset = 434.215 Hz at 3T
        etl        = EPI factor

We assume that the acceleration factor (SENSE) is already accounted for in the EPI factor (which Philips does). For example, a matrix of 128x128 with SENSE=2 will give an EPI factor of 67.

Luis Concha
March, 2015
INB, UNAM

"
}



if [ "$#" -lt 1 ]; then
  echo "[ERROR] - Not enough arguments"
  help
  exit 2
fi


declare -i i
i=1
verbose=1
for arg in "$@"
do
  case "$arg" in
  -h|-help) 
    help
    exit 1
  ;;

  -quiet)
    verbose=0
  ;;
  esac
  i=$[$i+1]
done



EPIfactor=`grep "EPI factor" $PAR | awk -F: '{print $2}' | sed 's/ //g' | tr -dc '[[:print:]]'`
WFS=`grep "Water Fat shift" $PAR | awk -F: '{print $2}' | sed 's/ //g' | tr -dc '[[:print:]]'`
FreqOffset=434.215


if [ $verbose -eq 1 ]
then
echo "
  EPI factor (etl) (n k-space lines) : $EPIfactor
  Water fat shift (pixels)           : $WFS 
  Frequency offset at 3T (Hz)        : $FreqOffset
  
  dwell = (((1000 * wfs)/(FreqOffset * (etl+1))
"
fi


numerator=`echo "1000 * $WFS" | bc -l`
denominator=`echo "$FreqOffset * (($EPIfactor +1))" | bc -l`

dwell=`echo "($numerator / $denominator)" | bc -l`

echo "DWELL (ms) = $dwell"


C4topup=`echo "$dwell * $EPIfactor / 1000" | bc -l`

if [ $verbose -eq 1 ]
then
echo "
So, for topup we need in the fourth colum of the acq params file:
C4 = dwell (ms) * EPIfactor / 1000
   = $dwell * $EPIfactor / 1000
   = $C4topup
"
else
  echo "C4topup    = $C4topup"
fi