#!/bin/bash

nii=$1
slice_order=$2
out=$3





help(){
  echo ""
  echo "
  `basename $0` <nii> <slice_order> <out>

  nii         : Input nii[.gz] file.
  slice_order : How slices were acquired. Options are:
                alt+z (interleaved, bottom-to-top)
                alt-z (interleaved, top-to-bottom)
                seq-up (sequential bottom-to-top)
                seq-dn (sequential top-to-bottom)

This script will look for the corresponding .json file 
and output a new .json file with the slice timing info added.


LU15 (0N(H4
INB, UNAM
April 2018
lconcha@unam.mx

Extended by Itzamná Sánchez Moncada
July 2018.


"
}


if [ "$#" -lt 3 ]; then
  echo "[ERROR] - Not enough arguments"
  help
  exit 2
fi




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
done


case $slice_order in
  alt+z)
    echolor yellow "Slice ordering is alt+z"
  ;;
  alt-z)
    echolor yellow "Slice ordering is alt-z"
  ;;
  seq-up)
    echolor yellow "Slice ordering is seq-up"
  ;;
  seq-dn)
    echolor yellow "Slice ordering is seq-dn"
  ;;
  *)
    echolor red " --> `basename $0` $1 $2 $3"
    echolor red "Sorry, only alt+z is supported now"
    echolor red "  You requested $slice_order"
    echolor red "  Perhaps it is a typo, or maybe you want something I cannot do yet. Bye."
    exit 2
  ;;
esac




json=${nii%.nii.gz}.json

if [ ! -f $nii ]
then
  echolor red "ERROR Cannot find file $nii"
  return 2
fi

if [ ! -f $json ]
then
  echolor red "ERROR Cannot find file $json"
  return 2
fi


TR=`grep RepetitionTime $json | awk -F: '{print $2}' | sed s/,//`
nslices=`fslinfo $nii | grep ^dim3 | awk '{print $2}'`
Tacq=`mrcalc $TR $nslices -div`


if [[ "$slice_order" = "alt+z" ]]
then
  increment=`mrcalc $TR  $nslices -div`

  #first package
  t=0
  for slice in `seq 1 2 $nslices`
  do
   #echolor cyan "Slice $slice, t: $t" 
   echo $t >> /tmp/slicetiming_$$_A
   t=`mrcalc $t $Tacq -add`
  done


  #second package
  lastOne=`tail -n 1 /tmp/slicetiming_$$_A`
  t=`mrcalc $lastOne $Tacq -add`
  for slice in `seq 2 2 $nslices`
  do
   #echolor cyan "Slice $slice, t: $t" 
   echo $t >> /tmp/slicetiming_$$_B
   t=`mrcalc $t $Tacq -add`
  done

  paste /tmp/slicetiming_$$_A /tmp/slicetiming_$$_B | while read line
  do
    printf "%s " $line >> /tmp/slicetiming_$$_C
  done
  printf "\n"  >> /tmp/slicetiming_$$_C
  times=`awk 'BEGIN {OFS=","};{$1=$1; print $0}'  /tmp/slicetiming_$$_C `
  

 head -n -1 $json | head -c-1  > /tmp/slicetiming_$$_json
 printf '%s\n' ","  >> /tmp/slicetiming_$$_json
 printf "    \"%s\": [%s]\n}" "SliceTiming" $times >> /tmp/slicetiming_$$_json
 if [ $verbose -eq 1 ]
 then
  echolor yellow "TR = $TR"
  echolor yellow "Number of slices = $nslices"
  echolor yellow "Time to acquire a slice is (TR/nslices) : $Tacq"
  echolor yellow "Slice timings are:"
  echolor yellow "$times"
  echolor yellow "  Writing output .json file: $out"
 fi
 cat /tmp/slicetiming_$$_json > $out
 
rm -fR /tmp/slicetiming_$$_*

elif [[ "$slice_order" = "alt-z" ]]
then
  increment=`mrcalc $TR  $nslices -div`

  #first package
  t=0
  for slice in `seq 1 2 $nslices`
  do
   #echolor cyan "Slice $slice, t: $t" 
   echo $t >> /tmp/slicetiming_$$_A
   t=`mrcalc $t $Tacq -add`
  done


  #second package
  lastOne=`tail -n 1 /tmp/slicetiming_$$_A`
  t=`mrcalc $lastOne $Tacq -add`
  for slice in `seq 2 2 $nslices`
  do
   #echolor cyan "Slice $slice, t: $t" 
   echo $t >> /tmp/slicetiming_$$_B
   t=`mrcalc $t $Tacq -add`
  done

  paste /tmp/slicetiming_$$_A /tmp/slicetiming_$$_B | while read line
  do
    printf "%s " $line >> /tmp/slicetiming_$$_C
  done
  printf "\n"  >> /tmp/slicetiming_$$_C
  times=`cat /tmp/slicetiming_$$_C`
  echo $times | tr ' ' '\n' | tac | tr '\n' ' ' > /tmp/slicetiming_$$_C
  timesRev=`awk 'BEGIN {OFS=","};{$1=$1; print $0}'  /tmp/slicetiming_$$_C`  

 head -n -1 $json | head -c-1  > /tmp/slicetiming_$$_json
 printf '%s\n' ","  >> /tmp/slicetiming_$$_json
 printf "    \"%s\": [%s]\n}" "SliceTiming" $timesRev >> /tmp/slicetiming_$$_json
 if [ $verbose -eq 1 ]
 then
  echolor yellow "TR = $TR"
  echolor yellow "Number of slices = $nslices"
  echolor yellow "Time to acquire a slice is (TR/nslices) : $Tacq"
  echolor yellow "Slice timings are:"
  echolor yellow "$timesRev"
  echolor yellow "  Writing output .json file: $out"
 fi
 cat /tmp/slicetiming_$$_json > $out
 
rm -fR /tmp/slicetiming_$$_*

elif [[ "$slice_order" = "seq-up" ]]
then

  t=0
  for slice in `seq 1 1 $nslices`
  do
   echolor cyan "Slice $slice, t: $t" 
   echo $t >> /tmp/slicetiming_$$_A
   t=`mrcalc $t $Tacq -add`
  done
  paste /tmp/slicetiming_$$_A | while read line
  do
    printf "%s " $line >> /tmp/slicetiming_$$_C
  done
  printf "\n"  >> /tmp/slicetiming_$$_C
  times=`awk 'BEGIN {OFS=","};{$1=$1; print $0}'  /tmp/slicetiming_$$_C `

 head -n -1 $json | head -c-1  > /tmp/slicetiming_$$_json
 printf '%s\n' ","  >> /tmp/slicetiming_$$_json
 printf "    \"%s\": [%s]\n}" "SliceTiming" $times >> /tmp/slicetiming_$$_json
 if [ $verbose -eq 1 ]
 then
  echolor yellow "TR = $TR"
  echolor yellow "Number of slices = $nslices"
  echolor yellow "Time to acquire a slice is (TR/nslices) : $Tacq"
  echolor yellow "Slice timings are:"
  echolor yellow "$times"
  echolor yellow "  Writing output .json file: $out"
 fi
 cat /tmp/slicetiming_$$_json > $out
 
rm -fR /tmp/slicetiming_$$_*


elif [[ "$slice_order" = "seq-dn" ]]
then

   t=0
  for slice in `seq 1 1 $nslices`
  do
   echolor cyan "Slice $slice, t: $t" 
   echo $t >> /tmp/slicetiming_$$_A
   t=`mrcalc $t $Tacq -add`
  done
  paste /tmp/slicetiming_$$_A | while read line
  do
    printf "%s " $line >> /tmp/slicetiming_$$_C
  done
  printf "\n"  >> /tmp/slicetiming_$$_C
  times=`cat /tmp/slicetiming_$$_C`
  echo $times | tr ' ' '\n' | tac | tr '\n' ' ' > /tmp/slicetiming_$$_C
  timesRev=`awk 'BEGIN {OFS=","};{$1=$1; print $0}'  /tmp/slicetiming_$$_C`

 head -n -1 $json | head -c-1  > /tmp/slicetiming_$$_json
 printf '%s\n' ","  >> /tmp/slicetiming_$$_json
 printf "    \"%s\": [%s]\n}" "SliceTiming" $timesRev >> /tmp/slicetiming_$$_json
 if [ $verbose -eq 1 ]
 then
  echolor yellow "TR = $TR"
  echolor yellow "Number of slices = $nslices"
  echolor yellow "Time to acquire a slice is (TR/nslices) : $Tacq"
  echolor yellow "Slice timings are:"
  echolor yellow "$timesRev"
  echolor yellow "  Writing output .json file: $out"
 fi
 cat /tmp/slicetiming_$$_json > $out
 
rm -fR /tmp/slicetiming_$$_*

fi