#!/bin/bash
source ~/noelsoft/BashTools/my_do_cmd



print_help()
{
  echo "
  `basename $0` <dti_1.nii.gz> [dti_n.nii.gz] [...] <averageDTI.nii.gz>


  Luis Concha - INB
  Agosto 2011
  "

}




if [ $# -lt 2 ] 
then
  echo "  ERROR: Need more arguments..."
  print_help
  exit 1
fi



fakeflag=""
for arg in "$@"
do

	case "$arg" in
		-h|-help) 
		print_help
		exit 1
		;;

      esac
done








# average DTI volumes of the same subject and session (offline NEX)
export FSLOUTPUTTYPE=NIFTI

last=$#
eval outfile=\${$last}


i=1
imlist=""
while [ "$i" -lt "$last" ]
do
    eval infile=\${$i}
    echo "Will average: $infile"
    imlist="$imlist $infile"
    i=`expr $i + 1`
done

echo "outfile: $outfile"


nFrames=`fslsize $infile | grep ^dim4 | awk '{print $2}'`
echo "nFrames: $nFrames"


hasErrors=0
for im in $imlist
do
  this_nFrames=`fslsize $im | grep ^dim4 | awk '{print $2}'`
  if [ $this_nFrames -eq $nFrames ]
  then
    echo "Dimensions OK for $im"
  else
    echo "ERROR: Dimensions are not equal in file $im"
    hasErrors=1
  fi
done

if [ $hasErrors -eq 1 ]
then
  echo "There are errors. Bye."
  exit 1
fi


tmpDir=/tmp/`random_string`
mkdir $tmpDir


nFrames_index0=$(( $nFrames - 1 ))
declare -a imArray=($imlist)
echo "there are ${#imArray[@]} files"


for frame in `seq 0 $nFrames_index0`
do
  echo $frame
  zframe=`zeropad $frame 4`
  
  # extract frames
  for index in `seq 0 $(( ${#imArray[@]} - 1))`
  do
    thisfile=${imArray[$index]}
    my_do_cmd $fakeflag fslroi $thisfile ${tmpDir}/frame_${zframe}_${index} $frame 1
    thisFrameArray[$index]=${tmpDir}/frame_${zframe}_${index}.nii
  done

  # Register frames
  refFrame=${thisFrameArray[0]}
  for index in `seq 1 $(( ${#thisFrameArray[@]} - 1))`
  do
    thisfile=${thisFrameArray[$index]}
    my_do_cmd $fakeflag flirt -dof 6 -ref $refFrame -in $thisfile -out ${tmpDir}/r_${zframe}_${index}
  done

  # Average the frames
  my_do_cmd $fakeflag fslmerge -t ${tmpDir}/merged_frame_${zframe} $refFrame ${tmpDir}/r_${zframe}_*
  my_do_cmd $fakeflag fslmaths ${tmpDir}/merged_frame_${zframe}.nii -Tmean ${tmpDir}/av_frame_${zframe}
done



# merge the frames
my_do_cmd $fakeflag fslmerge -t $outfile ${tmpDir}/av_frame_* 
gzip -v $outfile

rm -fR $tmpDir


