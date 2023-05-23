#!/bin/bash

inDir=$1



method=${inDir}/method

echoSpacing=`grep PVM_EpiEchoSpacing= $method | awk -F= '{print $2}'`
nEchoesEPI=`grep PVM_EpiNEchoes= $method | awk -F= '{print $2}'`
echoTrainTime=`mrcalc $nEchoesEPI 1 -sub $echoSpacing 0.001 -mul -mul`


echo "https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/eddy/Faq#How_do_I_know_what_to_put_into_my_--acqp_file"
echo ""
echo "EPI echo spacing:     $echoSpacing ms"
echo "number of EPI echoes: $nEchoesEPI"
echo "acqp last column:     $echoTrainTime"



