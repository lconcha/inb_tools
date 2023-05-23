#!/bin/bash


print_help()
{
echo "
`basename $0` <IN.tck> <OUT.tck> [options]
 
 Filter tractography results using labels drawn using freesurfer freeview.

-or <.label>
-and <.label>
-not <.label>
-ref <imagen.nii>  (This image is used as reference for turning labels into a volume)

Luis Concha
INB, UNAM.
2011
"

}

if [ $# -lt 3 ] 
then
	echo " ERROR: Need more arguments..."
	print_help
	exit 1
fi


declare -i i
i=1


AND_list=""
NOT_list=""
OR_list=""
for arg in "$@"
do
  case "$arg" in
  -h|-help) 
    print_help
    exit 1
  ;;
  -and)
    nextarg=`expr $i + 1`
    eval AND=\${${nextarg}}
    AND_list="$AND_list $AND"
  ;;
  -not)
    nextarg=`expr $i + 1`
    eval NOT=\${${nextarg}}
    NOT_list="$NOT_list $NOT"
  ;;
  -or)
    nextarg=`expr $i + 1`
    eval OR=\${${nextarg}}
    OR_list="$OR_list $OR"
  ;;
  -ref)
    nextarg=`expr $i + 1`
    eval ref=\${${nextarg}}
  ;;
  esac
  i=$[$i+1]
done


tckIN=$1
tckOUT=$2




# Make a temp directory
tmpDir=/tmp/mrtrix_proc_$$
mkdir $tmpDir


islabel()
{
    if [ -z `echo $1 | grep .label` ]
    then
	echo 0
    else
	echo 1 
    fi

}


i=0
for f in $AND_list
do
  if [ `islabel $f` -eq 1 ]
  then
      if [ -z $ref ]
      then
	  echo "If using labels, you MUST use the -ref switch."
	  exit 1
      fi
      echo "Converting $f to a volume"
      mri_label2vol --label $f --o ${tmpDir}/AND_${i}.nii --temp $ref --regheader $ref
  else
      echo copiando $f a ${tmpDir}/AND_${i}
      imcp $f ${tmpDir}/AND_${i}
  fi
i=$(($i +1))
done

i=0
for f in $NOT_list
do
  if [ `islabel $f` -eq 1 ]
  then
      if [ -z $ref ]
      then
	  echo "If using labels, you MUST use the -ref switch."
	  exit 1
      fi
      echo "Converting $f to a volume"
      mri_label2vol --label $f --o ${tmpDir}/NOT_${i}.nii --temp $ref --regheader $ref
  else
      echo copiando $f a ${tmpDir}/AND_${i}
      imcp $f ${tmpDir}/NOT_${i}
  fi
i=$(($i +1))
done



for f in $OR_list
do
  if [ `islabel $f` -eq 1 ]
  then
      if [ -z $ref ]
      then
	  echo "If using labels, you MUST use the -ref switch."
	  exit 1
      fi
      echo "Converting $f to a volume"
      mri_label2vol --label $f --o ${tmpDir}/OR_${i}.nii --temp $ref --regheader $ref
  else
      echo copiando $f a ${tmpDir}/AND_${i}
      imcp $f ${tmpDir}/OR_${i}.nii
  fi
i=$(($i +1))
done

INCLUDE_list=`ls ${tmpDir}/AND*.ni* 2>/dev/null`
EXCLUDE_list=`ls ${tmpDir}/NOT*.ni* 2>/dev/null`
OR_list=`ls ${tmpDir}/OR*.ni* 2>/dev/null`

or=""


if [ -z $OR_list ]
then
  echo "There are no ORs"
else
  FSLOUTPUTTYPE=NIFTI
  echo fslmerge -t ${tmpDir}/OR.nii $OR_list
  fslmerge -t ${tmpDir}/OR.nii $OR_list
  fslmaths ${tmpDir}/OR.nii -Tmax ${tmpDir}/OR2.nii
  fslmaths ${tmpDir}/OR2.nii -bin ${tmpDir}/ORb.nii
  or="-include ${tmpDir}/ORb.nii"
fi


inc=""
exc=""
for f in $INCLUDE_list
do
  inc="$inc -include $f"
done
for f in $EXCLUDE_list
do
  exc="$exc -exclude $f"
done

echo filter_tracks $inc $exc $or $tckIN $tckOUT
filter_tracks $inc $exc $or $tckIN $tckOUT


if [ ! -z $ref ]
then
  tracks2prob -fraction -template $ref $tckOUT ${tckOUT%.tck}_p.nii
fi

rm -fR $tmpDir
