#!/bin/bash
source `which my_do_cmd`
FSLOUTPUTTYPE=NIFTI

max_iter=10


print_help()
{
  echo "
  `basename $0` <dwi> <gradients.encodig> <mask> <fa> <fa_threshold> <output_response> <output_sfMask> [Options]

Options:

-max_iter <int>    Maximum number of iterations. Default=$max_iter.

  Luis Concha
  INB, UNAM
  Feb, 2014.			
"
}


if [ $# -lt 6 ] 
then
  echo " ERROR: Need more arguments..."
  print_help
  exit 1
fi



declare -i i
i=1
skip=1

for arg in "$@"
do
  case "$arg" in
    -h|-help) 
      print_help
      exit 1
    ;;
    -max_iter)
      nextarg=`expr $i + 1`
      eval max_iter=\${${nextarg}}
    ;;
    esac
    i=$[$i+1]
done



tmpDir=/tmp/response_$$
mkdir $tmpDir


dwi=$1
gradients=$2
mask=$3
fa=$4
FAthresh=$5
output_response=$6
output_sf=$7
directions=/home/inb/lconcha/fmrilab_software/tools/120Dirs.txt





echo "Computing the first version of single fibre mask"
sf=${tmpDir}/sf.nii
gen_WM_mask \
 -grad $gradients \
 $dwi $mask - | erode - \
 -npass 3 - | mrmult - \
 $fa - | threshold - \
 -abs $FAthresh $sf
mrconvert -datatype uint8 $sf ${tmpDir}/sf1.nii
sf=${tmpDir}/sf1.nii
echo "  single fiber mask created. Going into loop."


est_resp_iter()
{

  dwi=$1
  gradients=$2
  iter=$3
  tmpDir=$4
  prev_sf=${tmpDir}/sf${iter}.nii
  new_sf=${tmpDir}/sf$(( $iter +1 )).nii

  CSD=${tmpDir}/CSD.nii
  response=${tmpDir}/response.txt

  for f in $response $CSD ${tmpDir}/CSD_masked.nii ${tmpDir}/proc_peaks.nii ${tmpDir}/proc_amps.nii ${tmpDir}/proc_amps_bin_logical.nii ${tmpDir}/proc_amps_bin.nii
  do
    rm -f $f
  done

  
  my_do_cmd estimate_response \
    -grad $gradients \
    -lmax 6 \
    $dwi \
    $prev_sf \
    $response

  if [ -z "`grep nan $response`" ]
  then
    echo "  [iteration $iter] Response function seems OK:"
    cat $response
  else
    echo "FAILED to compute the response function. Cannot compute CSD, bye."
    echo Response is: `cat $response`
    echo "Quitting now!"
    rm -fR $tmpDir
    exit 2
  fi

  cat $response > ${tmpDir}/responses.txt

  my_do_cmd csdeconv -quiet \
    $dwi \
    -grad $gradients \
    $response \
    -lmax 6 \
    -mask $prev_sf \
    $CSD


  my_do_cmd find_SH_peaks -quiet \
    $CSD \
    $directions \
    ${tmpDir}/proc_peaks.nii

  my_do_cmd dir2amp \
    ${tmpDir}/proc_peaks.nii -quiet \
    ${tmpDir}/proc_amps.nii

  my_do_cmd threshold \
      ${tmpDir}/proc_amps.nii \
      -abs 0.1 \
      ${tmpDir}/proc_amps_bin_logical.nii
  
  my_do_cmd mrconvert -quiet \
     -datatype uint8 \
     ${tmpDir}/proc_amps_bin_logical.nii \
     ${tmpDir}/proc_amps_bin.nii

  my_do_cmd fslsplit \
    ${tmpDir}/proc_amps_bin.nii \
    ${tmpDir}/tmp_amps

  my_do_cmd fslmaths \
    ${tmpDir}/tmp_amps0000 \
    -add ${tmpDir}/tmp_amps0001 \
    -add ${tmpDir}/tmp_amps0002 \
    ${tmpDir}/nFibers \

  my_do_cmd fslmaths \
    ${tmpDir}/nFibers \
    -uthr 1 -bin \
    $new_sf -odt char

  
  maxFib=`fslstats ${tmpDir}/nFibers -r | awk '{print $2}'`
  maxFib=${maxFib:0:1}
  echo $maxFib > $tmpDir/maxFib.txt
}


maxFib=3
echo $maxFib > $tmpDir/maxFib.txt
echo "  Info: Will atempt at most $max_iter iterations."
for i in `seq $max_iter | xargs`
do
  prev_sf=${tmpDir}/sf${i}.nii
  nVox=`fslstats $prev_sf -V | awk '{print $1}'`
  echo "Going into iteration $i/$max_iter. Max Fiber is $maxFib. Working on $nVox voxels"
  est_resp_iter \
    $dwi \
    $gradients \
    $i \
    $tmpDir 

  maxFib=`cat ${tmpDir}/maxFib.txt`

 echo "  === After iteration $i, maxFib is $maxFib"
  if [ $maxFib -eq 1 ]
  then
    echo "Arrived at final response function"
    final_sf=${tmpDir}/sf$(( $iter +1 )).nii
    break
  fi
done



if [ $i -lt $max_iter ]
then
   echo " Info: Found a good response function in $i iterations".
else
   echo " Warning: It seems that we reached the maximum iterations allowed."
   final_sf=${tmpDir}/sf${i}.nii
fi



nVox=`fslstats $final_sf -V | awk '{print $1}'`
nVoxth=150
if [ $nVox -lt $nVoxth ]
then
  echo "ERROR: Final single fiber mask contains less than $nVoxth voxels. response function may not be realistic"
else
  echo "INFO: Final single fiber mask contains $nVox voxels."
  cp -v ${tmpDir}/response.txt $output_response
  cp -v $final_sf $output_sf
  cat $output_response
  
fi

rm -fR $tmpDir


