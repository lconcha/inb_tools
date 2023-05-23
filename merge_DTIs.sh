#!/bin/bash
source ~/noelsoft/BashTools/my_do_cmd

print_help()
{
  echo "
  `basename $0` merged.nii.gz -images \"list Of Files\" -bvals \"list of bvals \" -bvecs \"list of bvecs \" 


  Luis Concha
  INB
  March 2011			
"
}



if [ $# -lt 2 ] 
then
  echo " ERROR: Need more arguments..."
  print_help
  exit 1
fi


mergedDTI=$1
tmpFile=$$_merging.txt


declare -i i
i=1
flipOptions=""
clobber=0
for arg in "$@"
do

  case "$arg" in
  -h|-help) 
    print_help
    exit 1
  ;;
  -images)
    nextarg=`expr $i + 1`
    eval list_images=\${${nextarg}}
  ;;
  -bvals)
    nextarg=`expr $i + 1`
    eval list_bvals=\${${nextarg}}
  ;;
  -bvecs)
    nextarg=`expr $i + 1`
    eval list_bvecs=\${${nextarg}}
  ;;
  -clobber)
    clobber=1
  ;;
  esac
  i=$[$i+1]
done

if [ -f $mergedDTI ]
then
  if [ $clobber -eq 0 ]
  then
    echo "File $mergedDTI already exists. Use -clobber to overwrite. Quitting."
    exit 1
  else
    echo "Overwriting $mergedDTI"
    rm -f $mergedDTI 
  fi
fi


echo "Will merge these files:"
for f in $list_images
do
  echo "  $f"
done

echo "With these bvals:"
for f in $list_bvals
do
  echo "  $f"
done

echo "With these bvecs:"
for f in $list_bvecs
do
  echo "  $f"
done

echo "Into:"
echo "  $mergedDTI"
echo "  ${mergedDTI%.nii.gz}.bval"
echo "  ${mergedDTI%.nii.gz}.bvec"


#### Merge the DTIS
my_do_cmd fslmerge -t $mergedDTI $list_images



##### Merge the gradient info
echo "Now the bvals and bvecs..."
rm -f $tmpFile
for f in $list_bvals
do
  transpose_table.sh $f >> $tmpFile
done
awk '{print $1,$2,$3}' $tmpFile > ${tmpFile}2
echo "transpose_table.sh $tmpFile2 > ${mergedDTI%.nii.gz}.bval"
transpose_table.sh ${tmpFile}2 > ${mergedDTI%.nii.gz}.bval

rm -f $tmpFile
for f in $list_bvecs
do
  transpose_table.sh $f >> $tmpFile
done

awk '{print $1,$2,$3}' $tmpFile > ${tmpFile}2
echo "transpose_table.sh ${tmpFile}2 > ${mergedDTI%.nii.gz}.bvec"
transpose_table.sh ${tmpFile}2 > ${mergedDTI%.nii.gz}.bvec

rm -f $tmpFile ${tmpFile}2



#### Final check of things
nVols=`fslinfo $mergedDTI | grep ^dim4 | awk '{print $2}'`
nBvals=`transpose_table.sh ${mergedDTI%.nii.gz}.bval | wc -l`

echo "Cheking..."
echo "  Number of frames in 4th dimension : $nVols"
echo "  Number of b values                : $nBvals"
if [ $nVols -eq $nBvals ]
then
  echo "Things seem OK!"
else
  echo "ERROR: Mismatch between number of dimensions and bvals!!!"
fi
