#!/bin/bash
sujeto=$1

brain=${SUBJECTS_DIR}/${sujeto}/mri/brain.mgz
piales=${SUBJECTS_DIR}/${sujeto}/surf/?h.pial
blancas=${SUBJECTS_DIR}/${sujeto}/surf/?h.white

freeview -v $brain -f $piales $blancas
