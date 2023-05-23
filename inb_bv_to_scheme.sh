#!/bin/bash

function help() {
echo "
`basename $0` bvals bvecs DwGradSep DwGradDur TE out.scheme

Create a camino-style scheme file from bvals and bvecs.
You must know Delta and delta (DwGradSep and DwGradDur, respectively).

DwGradSep, DwGradDur and TE are given in ms.


Luis Concha
March 2017
INB, UNAM

"
}



if [ "$#" -lt 6 ]; then
  echo "[ERROR] - Not enough arguments"
  help
  exit 2
fi



bvals=$1
bvecs=$2
DwGradSep=$3
DwGradDur=$4
TE=$5
scheme=$6


matlabcommand=/home/inb/lconcha/fmrilab_software/MATLAB/Matlab13-alt/bin/matlab


echo bvals is $bvals
echo bvecs is $bvecs
echo DwGradSep is $DwGradSep ms
echo DwGradDur is $DwGradDur ms
echo TE is $TE ms
echo scheme will be $scheme


$matlabcommand -nodisplay <<EOF
scheme = bv_to_scheme('$bvals','$bvecs',$DwGradSep,$DwGradDur,$TE,'$scheme');
EOF

echo done.