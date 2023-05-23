#!/bin/bash
#Preprocessing script for rat brains, using Fisher355 template and MINC files converted from nifti from brkraw
source `which my_do_cmd`
fakeflag=""

export PATH=/home/inb/lconcha/fmrilab_software/minc-toolkit-extras:$PATH


#atlasdir=/datos/syphon/lconcha/software/Fischer344atlas/Fischer344_nii_v4
atlasdir=/misc/mansfield/lconcha/exp/ratAtlas/fischer344/Fischer344_nii_v4
niter=3

function help(){
echo "
`basename $0` <-i movingimage> <-o outbase> [-d atlasdir]


Bias field correction and denoising of an anatomical image.



-i movingimage    Image to move register into atlas space.
                  Should already have been bias field corrected, but one more correction
                  will be performed using the resulting mask.
                  
-o outbase        Prefix for outputs:
                  _toatlas.mat  (affine registration to atlas).
                  _mask.nii.gz  (brain mask in native space)
                  _bcorr.nii.gz (input image now with one more bias field correction)


Options:

-d atlasdir       The full path to the atlas containing Fischer344_template.nii
                  Currently: $atlasdir
-n                Number of iterations. Default is $niter
-t                Specify temporal directory
-k                Do not delete temporal directory
-h                Show this help.
                  

LU15 (0N(H4
(inspired and assisted by Eduardo Garza)
INB-UNAM
Feb 2022
lconcha@unam.mx
"
}


dononlinear=0
tmpdir=""
keep_tmp=0
while getopts i:o:d:n:t:kh flag
do
    case "${flag}" in
        i) input=${OPTARG};;
        o) outbase=${OPTARG};;
        d) atlasdir=${OPTARG};;
        n) niter=${OPTARG};;
        t) tmpdir=${OPTARG};;
        k) keep_tmp=1;;
        h) help;exit 2;;
    esac
done



if [ ! -f "$input" ]; then echo "ERROR: Cannot find input image"; help;exit 2;fi
if [ -z "$outbase" ]; then    echo "ERROR: Please specify outbase with -o"; help;exit 2;fi








calc(){ awk "BEGIN { print "$*" }"; }
tmpdir=$(mktemp -d)


# convert to minc and remove obliqueness
my_do_cmd $fakeflag nii2mnc -quiet $input ${tmpdir}/flip.mnc
my_do_cmd $fakeflag clean_and_center_minc.pl $tmpdir/flip.mnc $tmpdir/centered.mnc
my_do_cmd $fakeflag mincnorm $tmpdir/centered.mnc $tmpdir/centered_norm.mnc -out_ceil 1 -out_floor 0
rm $tmpdir/centered.mnc
mv $tmpdir/centered_norm.mnc $tmpdir/centered.mnc



# full volume mask
my_do_cmd $fakeflag mincmath $tmpdir/centered.mnc -mul -const 0 -add -const 1 $tmpdir/wholevolumemask.mnc


echolor green "Quick N4 as a first pass."
my_do_cmd $fakeflag N4BiasFieldCorrection -d 3 \
  -i $tmpdir/centered.mnc \
  -r 1 \
  -s 4 \
  -w $tmpdir/wholevolumemask.mnc \
  -o [${tmpdir}/biascorrected.mnc,${tmpdir}/biasfield.mnc]


for i in $(seq 1 $niter)
do
  echolor green "N4, iteration $i of $niter"
  my_do_cmd $fakeflag ThresholdImage 3 ${tmpdir}/biascorrected.mnc $tmpdir/otsu.mnc  Otsu 1
  my_do_cmd $fakeflag N4BiasFieldCorrection -d 3 \
  -s 2 \
  -i ${tmpdir}/biascorrected.mnc \
  -b [30] \
  -c [200x200x200,0.0] \
  -r 1 \
  -w $tmpdir/otsu.mnc \
  -x $tmpdir/wholevolumemask.mnc \
  -o [${tmpdir}/biascorrected.mnc,${tmpdir}/biasfield.mnc]
done
  


my_do_cmd $fakeflag mincnorm ${tmpdir}/biascorrected.mnc ${tmpdir}/biascorrected_norm.mnc -out_ceil 1 -out_floor 0
my_do_cmd $fakeflag mv  ${tmpdir}/biascorrected_norm.mnc ${tmpdir}/biascorrected.mnc


my_do_cmd $fakeflag DenoiseImage -d 3 \
  -i ${tmpdir}/biascorrected.mnc \
  -o [${tmpdir}/biascorrected_denoised.mnc,${tmpdir}/noise.mnc]


for f in centered biascorrected biasfield otsu biascorrected_denoised noise
do
  my_do_cmd $fakeflag mnc2nii -quiet $tmpdir/${f}.mnc ${outbase}_${f}.nii > /dev/null
done

rm -fR $tmpdir
