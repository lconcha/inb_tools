#!/bin/bash

# cambiar la orientacion de los monos de Hugo

original=$1
reoriented=$2

fslswapdim $original x y -z /tmp/$$_reorientado1.nii.gz
fslorient -deleteorient /tmp/$$_reorientado1.nii.gz
fslswapdim /tmp/$$_reorientado1.nii.gz x -z -y /tmp/$$_reorientado2.nii.gz
fslorient -setqformcode 1 /tmp/$$_reorientado2.nii.gz

mv /tmp/$$_reorientado2.nii.gz $reoriented

