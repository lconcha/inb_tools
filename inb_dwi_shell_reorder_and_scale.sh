#!/bin/bash
source `which my_do_cmd`

dwiIN=$1
noisemask=$2
dwiOUT=$3



help(){
  echo "

How to use:
  `basename $0` <dwiIN.mif> <noisemask.mif> <dwiOUT.mif>


This script will take a set of dwis and do two things:
  1) Reorder the volumes shell-by-shell in ascending b-value order.
  2) Rescale the DWIs, takig a correction factor from a noise-only ROI (noisemask.mif)



Based on the Matlab script by Ricardo Coronado-Leija.


LU15 (0N(H4
INB UNAM
March 2022
lconcha@unam.mx
  "
}


if [ $# -lt 3 ]
then
  echolor red "Not enough arguments"
	help
  exit 2
fi



tmpDir=$(mktemp -d)

shell=0
mrinfo -shell_indices $dwiIN | tr ' ' '\n' | while read "indices"
do
  if [ -z "$indices" ]; then continue;fi
  echolor yellow "-- shell $shell"
  echolor white "   $indices"
  my_do_cmd mrconvert $dwiIN -coord 3 $indices ${tmpDir}/shell_${shell}.mif
  my_do_cmd mrmath -axis 3 ${tmpDir}/shell_${shell}.mif mean ${tmpDir}/mean_${shell}.mif
  shell=$(( $shell +1 ))
done



my_do_cmd mrcat -axis 3 ${tmpDir}/mean_*.mif ${tmpDir}/allmeans.mif

mrstats -output mean -mask $noisemask ${tmpDir}/allmeans.mif | tee ${tmpDir}/meanvalues
maxvalue=$(cat ${tmpDir}/meanvalues | sort | head -n 1)

echo maxvalue is $maxvalue

#echolor yellow meanvalues
cat ${tmpDir}/meanvalues 

#echolor cyan "corr factors"
awk -v mx=$maxvalue '{print $1/mx}' ${tmpDir}/meanvalues  > ${tmpDir}/corrvalues


shell=0
cat ${tmpDir}/corrvalues | while read corrval
do
  my_do_cmd mrcalc ${tmpDir}/shell_${shell}.mif $corrval -mul ${tmpDir}/corrshell_${shell}.mif
  shell=$(( $shell +1 ))
done
my_do_cmd mrcat -axis 3 ${tmpDir}/corrshell_*.mif $dwiOUT


rm -fR $tmpDir
