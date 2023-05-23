#!/bin/bash
source `which my_do_cmd`
export FSLOUTPUTTYPE=NIFTI
# fakeflag="-fake"
fakeflag=""

DWI=$1
DWIout=$2
ref=$3
method=$4
keep_tmp=0


print_help()
{
  
 echo "

  `basename $0` <dwiIN.mif> <DWIOUT.mif> <ref|ref.mif> <method> [Options]

Use affine registration for each frame of a DWI data set to a reference volume.

The reference volume can be either:
  a) An index (starting at zero) of the dwiIN.mif data set.
  b) An image derived from the dwiIN (for example, the average b=0 volume).

method: A string of either:
  a) mrtrix. Uses mrregister. It is slower and not thoroughly tested. May not work.
  b) fsl (recommended) Uses flirt.


Options:
-keep_tmp



LU15 (0N(H4
lconcha@unam.mx
INB, UNAM
August, 2017
"
}



if [ $# -lt 2 ] 
then
	echo " ERROR: Need more arguments..."
	print_help
	exit 2
fi


declare -i arg_index
arg_index=1
for arg in "$@"
do
  case "$arg" in
  -h|-help) 
    print_help
    exit 1
  ;;
  -keep_tmp)
    keep_tmp=1
  ;;
  esac
  arg_index=$[$arg_index+1]
done









if [[ "$method" = "mrtrix" ]]
then
  nFrames=`mrinfo -size $DWI | awk '{print $4}'`
  for f in `seq 0 $(($nFrames -1))` 
  do
    frame=`zeropad $f 4` 
    my_do_cmd $fakeflag mrconvert -coord 3 $frame -axes 0,1,2 $DWI tmp_$$_${frame}.mif
    my_do_cmd $fakeflag mrregister tmp_$$_${frame}.mif $ref \
      -type affine  \
      -transformed tmp_$$_${frame}_t.mif  \
      -affine tmp_$$_${frame}_t.xfm \
      -affine_init_translation none \
      -affine_init_rotation none
  done
  my_do_cmd $fakeflag mrcat tmp_$$_*_t.mif tmp_$$_cat.mif
  my_do_cmd $fakeflag mrinfo -export_grad_mrtrix tmp_$$_grad.txt $DWI
  my_do_cmd $fakeflag mrconvert -grad tmp_$$_grad.txt tmp_$$_cat.mif $DWIout
  my_do_cmd $fakeflag rm tmp_$$_*
  exit 0
fi





if [[ "$method" = "fsl" ]]
then
  
  filename=$(basename "$1")
  extension="${filename#*.}"
  filename="${filename%.*}"

  input=$1
  output=$2
  ref=$3

  if [ "$ref" -eq "$ref" ] 2>/dev/null
  then
    echo "$ref is an integer !!"
    my_do_cmd $fakeflag mrconvert -coord 3 $ref $DWI /tmp/my_eddy_$$.mif
    ref=/tmp/my_eddy_$$.mif
  fi



 tmpDir=/tmp/my_eddy_$$ 
 mkdir $tmpDir



 input_tmp=${tmpDir}/input.nii
 mrconvert $input $input_tmp
 ref_tmp=${tmpDir}/ref.nii
 mrconvert $ref $ref_tmp 

  my_do_cmd $fakeflag fslsplit $input_tmp ${tmpDir}/tmp
  full_list=`ls ${tmpDir}/tmp????.nii*`

  for i in $full_list ; do
      echo processing $i
      echo processing $i >> ${output}.ecclog
      ${FSLDIR}/bin/flirt -in $i -ref $ref_tmp -nosearch -o $i -paddingsize 1 >> ${output}.ecclog
  done

  my_do_cmd $fakeflag mrcat -axis 3  $full_list $output
  
  if [ $keep_tmp - eq 1 ]
  then
    rm -fR $tmpDir /tmp/my_eddy_$$.mif
  else
    echolor orange " Not removing tmp dir: $tmpDir"
  fi
  exit 0
fi