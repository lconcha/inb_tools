#!/bin/bash
source `which my_do_cmd`





print_help()
{
echo "
`basename $0` <t1> <dwi> <outbase> [Options]

Options:

-t1_wm_pve <file>
-dwi_wm_pve <file>
-dwi_mask <file>

 LU15 (0N(H4
 INB, Feb 2015.
 lconcha@unam.mx

**************************************
 NO FUNCIONA, favor de utilizar inb_register_t1_to_dwi_via_csf.sh
**************************************
"
}


if [ $# -lt 1 ] 
then
	echo " ERROR: Need more arguments..."
	print_help
	exit 1
fi


t1=$1
dwi=$2
outbase=$3
do_dwi_mask=1
do_t1_pve=1
do_dwi_pve=1




declare -i index
for arg in "$@"
do
  case "$arg" in
    -h|-help) 
      print_help
      exit 1
    ;;
    -t1_wm_pve)
      nextarg=`expr $i + 1`
      eval t1_wm_pve=\${${nextarg}}
      do_t1_pve=0
    ;;
    -dwi_wm_pve)
      nextarg=`expr $i + 1`
      eval dwi_wm_pve=\${${nextarg}}
      do_dwi_pve=0
    ;;
    -dwi_mask)
      nextarg=`expr $i + 1`
      eval dwi_mask=\${${nextarg}}
      do_dwi_mask=0
    ;;
    esac
    i=$[$i+1]
done


tmpDir=/tmp/dwiRegister_`random_string`
mkdir $tmpDir


if [ $do_t1_pve -eq 1 ]
then
    echo "  Running FAST on $t1"
fi

if [ $do_dwi_pve -eq 1 ]
then
    echo "  Running FAST on $dwi"
fi

if [ $do_dwi_mask -eq 1 ]
then
    echo "  Running bet on $dwi"
    my_do_cmd fast -v -S 1 -n 3 -t 1 -I 1 -g -N \
    -o ${tmpDir}/Fast_t1 \
    $t1
fi


echo " No he acabado de programar!"
exit 2









# Note to self:
# the mask and the dwi_wm_pve may have different organization of the 
# data dimensions (stride, in mrtrix), and may be oriented differently,
# which can be checked with mrinfo or fslinfo.
# You must first correct this, using something like:
# mrconvert -force -axes 0,1,2 -stride 1,2,3 dwi_wm_pve.nii.gz  dwi_wm_pve_stride123.nii.gz


tmpDir=/tmp/dwiReg_`random_string`


# mkdir $tmpDir


# reorient everythinh to std

# my_do_cmd fslreorient2std $t1_wm_pve ${tmpDir}/t1_wm_pve
# my_do_cmd fslreorient2std $dwi_wm_pve ${tmpDir}/dwi_wm_pve
# my_do_cmd fslreorient2std $dwi_mask ${tmpDir}/dwi_mask


# print_step "Run FAST to obtain GM, WM and CSF tissue segmentations"
# my_do_cmd fast -v \
#   -t 2 \
#   -N \
#   -S 2 \
#   -o ${tmpDir}/fast \
#   $adc \
#   $fa



# linear initial transformation
my_do_cmd flirt -v \
  -in $dwi_wm_pve \
  -ref $t1_wm_pve \
  -dof 12 \
  -omat ${outbase}_lin_dwi2t1.mat
  -out ${outbase}_lin_dwi2t1

my_do_cmd fnirt -v \
  --ref=$t1_wm_pve \
  --in=$dwi_wm_pve \
  --inmask=$dwi_mask \
  --aff=${outbase}_lin_dwi2t1.mat  \
  --cout=${outbase}_nlin_dwi2t1_coef \
  --iout=${outbase}_nlin_dwi2t1







rm -fR $tmpDir


