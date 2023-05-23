#!/bin/bash
source `which my_do_cmd`

atlasDir=/home/inb/lconcha/fmrilab_software/mni_icbm152_nlin_asym_09c
atlas=${atlasDir}/mni_icbm152_t1_tal_nlin_asym_09c_2mm.nii


help(){
  echo ""
  echo "
  `basename $0` [options] <directory.feat>

Add the necessary information to a .feat directory when you did your registration steps outside of Feat.
This is useful if you register via fmriprep, ANTS or any other way.

If you do not add this information, high-level analyses will not run with Feat.

Got it from here:
https://neurostars.org/t/performing-full-glm-analysis-with-fsl-on-the-bold-images-preprocessed-by-fmriprep-without-re-registering-the-data-to-the-mni-space/784/2

and this video tutorial:
https://www.youtube.com/watch?time_continue=7&v=U3tG7JMEf7M

Options:
-atlas <full_path_to_atlas>  Default is $atlas
-mask <full_path_to_mask>    Default is to copy the one on the first level analysis.

LU15 (0N(H4
INB, UNAM
April 2018
Rev Aug 2018
lconcha@unam.mx


"
}



if [ "$#" -lt 1 ]; then
  echo "[ERROR] - Not enough arguments"
  help
  exit 2
fi


mask=""
for arg in "$@"
do
  case "$arg" in
  -h|-help)
    help
    exit 1
  ;;
  -atlas)
    #nextarg=`expr $i + 1`
    #eval atlas=\${${nextarg}}
    atlas=$2
    shift;shift
    echolor cyan "Set atlas to $atlas"
  ;;
  -mask)
    mask=$2
    echolor cyan "Set mask to $mask"
  shift;shift
  esac
done



feat=$1
echolor yellow " Working on $feat" 





mkdir -p $feat/reg
mkdir -p $feat/standard
mkdir -p $feat/reg_standard/reg $feat/reg_standard/stats

cp -vu $FSLDIR/etc/flirtsch/ident.mat $feat/reg/example_func2standard.mat
cp -vu $FSLDIR/etc/flirtsch/ident.mat $feat/reg/standard2example_func.mat

#cp -vu $feat/mean_func.nii.gz $feat/reg/standard.nii.gz
voxsize=`mrinfo -spacing $atlas | tr ' ' ','`
dimensions=`mrinfo -size $atlas | tr ' ' ','`
echolor cyan "Atlas is `basename $atlas`"
echolor cyan "    Voxel sizes: $voxsize"
echolor cyan "    Dimensions : $dimensions"

echo mrresize \
  -voxel $voxsize  \
  -size $dimensions \
  $feat/mean_func.nii.gz \
  $feat/reg/standard.nii.gz


my_do_cmd flirt -ref $atlas \
  -in $feat/mean_func.nii.gz \
  -out $feat/reg_standard/mean_func.nii.gz \
  -applyxfm -init $feat/reg/example_func2standard.mat

my_do_cmd flirt -ref $atlas \
  -in $feat/example_func.nii.gz \
  -out $feat/reg_standard/example_func.nii.gz \
  -applyxfm -init $feat/reg/example_func2standard.mat

cp -vu $atlas $feat/reg/standard.nii.gz

if [ -z "$mask" ]
then
  cp -v $feat/mask.nii.gz $feat/reg_standard/
else
  cp -v $mask $feat/reg_standard/mask.nii.gz
fi


echo "done."
