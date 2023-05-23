#!/bin/bash
source `which my_do_cmd`
fakeflag=""
c4topup=0.0438;# this is just a guess
eddybin=eddy_cuda9.1

help() {
echo "
  `basename $0` <dwi.nii[.gz]> <bvec> <bval> <outbase>



dwi    Should be denoised. Use dwidenoise or dipy_denoise_patch2self.


Suggestion:

Convert your images using brkraw. For example:
inb_anaconda_on
conda activate brkraw
brkraw gui -i /misc/bruker_pvDatasets2/nmrsu/20210324_110936_D13_Abraham_LUIS_PRUEBA_1_1



Options:
-fake
-c4topup <float>  Supply the fourth column for topup.
                  Default is $c4topup.
                  Not needed, because this script does not compute a fieldmap with topup.
-openmp           Force to run un CPU.

LU15 (0N(H4
INB, UNAM
April 2021
lconcha@unam.mx

"
}



if [ "$#" -lt 4 ]; then
  echo "[ERROR] - Not enough arguments"
  help
  exit 2
fi




declare -i i
i=1
for arg in "$@"
do
  case "$arg" in
  -h|-help)
    print_help
    exit 1
  ;;
  -fake)
    fakeflag="-fake"
  ;;
  -c4topup)
    nextarg=`expr $i + 1`
    eval c4topup=\${${nextarg}}
  ;;
  -openmp)
    echolor yellow "Will use CPU."
    eddybin=eddy_openmp
  ;;
  esac
  i=$[$i+1]
done


if [[ "$eddybin" = "eddy_cuda9.1" ]]
then
  echolor yellow "Checking if this machine can run $eddybin"
  errmsg=`$eddybin 2>  >(grep libraries)`
  if [ ! -z "$errmsg" ]
  then
    echo $errmsg
    echolor red "Configuration for $eddybin failed"
    echolor red "Check that cuda is installed and your PATH points to the correct libraries."
    echolor red "example: export LD_LIBRARY_PATH=/home/lconcha/anaconda3/envs/py27/lib:${LD_LIBRARY_PATH}}"
    echolor red "If you cannot use cuda, then use -openmp"
    exit 2
  else
    echolor yellow "Configuration for $eddybin is OK!"
  fi
fi



dwi=$1; #denoised
bvec=$2
bval=$3
outbase=$4

isOK=1
for f in $dwi $bvec $bval
do
  if [ ! -f $f ]
  then
    echolor red "Cannot find $f"
    isOK=0
  fi
done

if [ $isOK -eq 0 ]
then
  echolor red "There are errors, cannot continue."
  exit 2
fi


# make a mask
echolor yellow "Generating a mask"
mask=${outbase}_mask.nii.gz
my_do_cmd $fakeflag dwi2mask -fslgrad $bvec $bval $dwi $mask


# prepare things for eddy
acqp=${dwi%.nii.gz}_acqp.txt
index=${dwi%.nii.gz}_index.txt
nvols=`fslnvols $dwi`
echo 0 -1 0 $c4topup > $acqp
indx=""
for ((i=1; i<=$nvols; i+=1)); do indx="$indx 1"; done
echo $indx > $index


# run eddy without revpe or field map. Seems to work just fine.
echolor yellow "Running eddy"
my_do_cmd $fakeflag $eddybin --verbose \
  --imain=$dwi \
  --mask=$mask \
  --acqp=$acqp \
  --index=$index \
  --bvecs=$bvec \
  --bvals=$bval \
  --residuals=true \
  --repol=true \
  --out=$outbase

echolor yellow "Fixing bvecs to remove nan"
rbvec=${outbase}.eddy_rotated_bvecs
my_do_cmd $fakeflag sed -i 's/-nan/0/g' $rbvec


echolor yellow "Converting to mif"
my_do_cmd $fakeflag mrconvert ${outbase}.nii* -fslgrad $rbvec $bval ${outbase}.mif
