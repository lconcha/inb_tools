#!/bin/bash
source `which my_do_cmd`
export FSLOUTPUTTYPE=NIFTI

if [ -z `which topup` ]
  then
  echo "ERROR: fsl 5 is not configured."
  exit 127
fi


# INPUTS and defaults ##################################
DWI_yNeg=$1
bvals_yNeg=$2
bvecs_yNeg=$3
DWI_yPos=$4
bvals_yPos=$5
bvecs_yPos=$6
#mask=$7
outbase=$7

DWI_to_fix=$DWI_yPos
C4topup=0.047
fake=""
tmpDir=/tmp/inb_topup_`whoami`_$$/
keep_tmp=0
matlabBIN=/home/inb/lconcha/fmrilab_software/MATLAB/Matlab13-alt/bin/matlab
doCuda=0
###########################################################



print_help()
{
  echo "
  `basename $0` <DWIneg> <DWIneg.bval> <DWIneg.bvec> \\
  <DWIpos> <DWIpos.bval> <DWIpos.bvec> \\
  <outbase> [Options]


  Run topup on DWI data. Assumes two different acquisitions, one
  with the filling of k-space A>>P and the other as P>>A.
  There are many other ways to refer to these two acquisitions,
  another being positive blips, or negative blips. We will use pos and neg
  to refer to these.

  It is not trivial to know from the headers if it is a positive or negative
  blip EPI acquisition, so you must know this in advance. Fortunately, this is
  easy to know from visual inspection
  (see http://fsl.fmrib.ox.ac.uk/fsl/fslwiki/topup/Faq).

  Briefly, negative blips give you an image with a squashed frontal lobe, while
  positive blips give you a stretched frontal lobe.


  You do not need this script to run topup. It is here because understanding how
  topup works is a bit of a nightmare and I have a love/hate relationship with it.
  Oh, and expect a good 4 hours for your data to be corrected.

  Options:
  -fixPos (default): Fix the positive-blip acquisition.
  -fixNeg          : Fix the negative-blip acquisition.
  -C4topup <float> : The number that goes in the fourth column of the
  acqParams file for topup
  (see http://fsl.fmrib.ox.ac.uk/fsl/fslwiki/topup).
  If you have .PAR files, you can get this easily using
  inb_dwell_from_PAR.sh.
  Default is $C4topup, which may be wrong but it gets the job done.
  Note that if you have this value correct according you your data
  then the file with the topup field has the correct units and
  is scaled accordingly.
  -fake
  -keep_tmp
  -cuda            : Run Eddy with eddy_cuda

  LU15 (0N(H4
  INB, UNAM
  March 2015.
  lconcha@unam.mx
  "
}


if [ $# -lt 2 ]
  then
  echo " ERROR: Need more arguments..."
  print_help
  exit 1
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
    -fixPos)
    DWI_to_fix=$DWI_yPos
    ;;
    -fixNeg)
    DWI_to_fix=$DWI_yNeg
    ;;
    -C4topup)
    nextarg=`expr $i + 1`
    eval C4topup=\${${nextarg}}
    ;;
    -fake)
    fake="-fake"
    ;;
    -keep_tmp)
       keep_tmp=1
    ;;
    -matlabBIN)
    nextarg=`expr $i + 1`
    eval matlabBIN=\${${nextarg}}
    ;;
    -cuda)
      doCuda=1
    ;;
  esac
  i=$[$i+1]
done


mkdir $tmpDir







# see if we hava row or column vector
nCols=`awk 'BEGIN {FS=" "} ; END{print NF}' $bvals_yNeg`
if [ $nCols -eq 1 ]
then
  echo "[INFO] bvals are in column format. Good."
else
  echo "[INFO] bvals are in row format, changing to columns."
  transpose_table.sh $bvals_yNeg > ${tmpDir}/bvals_yNeg
  bvals_yNeg=${tmpDir}/bvals_yNeg
  transpose_table.sh $bvecs_yNeg > ${tmpDir}/bvecs_yNeg
  bvecs_yNeg=${tmpDir}/bvecs_yNeg
  transpose_table.sh $bvals_yPos > ${tmpDir}/bvals_yPos
  bvals_yPos=${tmpDir}/bvals_yPos
  transpose_table.sh $bvecs_yPos > ${tmpDir}/bvecs_yPos
  bvecs_yPos=${tmpDir}/bvecs_yPos
fi


# find the b=0 indices
index_b0_yNeg=`grep -n ^0 $bvals_yNeg | head -n 1 | awk -F: '{print $1}'`
index_b0_yPos=`grep -n ^0 $bvals_yPos | head -n 1 | awk -F: '{print $1}'`
echo "
yNeg: $DWI_yNeg
b0index: $(( $index_b0_yNeg -1 ))
yPos: $DWI_yPos
b0index: $(( $index_b0_yPos -1 ))
"




b0s_yNeg=${tmpDir}/b0s_yNeg.nii
b0s_yPos=${tmpDir}/b0s_yPos.nii
b0s_combined=$tmpDir/b0s_combined.nii
my_do_cmd fslroi $DWI_yNeg $b0s_yNeg $(( $index_b0_yNeg -1 )) 1
my_do_cmd fslroi $DWI_yPos $b0s_yPos $(( $index_b0_yPos -1 )) 1
my_do_cmd mrcat -axis 3 $b0s_yNeg $b0s_yPos $b0s_combined




# create acquisition parameters
# n_b0s_yNeg=`fslval $b0s_yNeg dim4`
# if [ $n_b0s_yNeg -eq 0 ]; then n_b0s_yNeg=1;fi
# n_b0s_yPos=`fslval $b0s_yPos dim4`
# if [ $n_b0s_yPos -eq 0 ]; then n_b0s_yPos=1;fi
# acqParams=acqParams.txt
# for v in `seq 1 $n_b0s_yNeg`
# do
#   echo 0 -1 0 $C4topup >> $acqParams
# done
# for v in `seq 1 $n_b0s_yPos`
# do
#   echo 0 1 0 $C4topup >> $acqParams
# done
# cat $acqParams

acqParams=${outbase}_acqParams.txt
echo 0 -1 0 $C4topup > $acqParams
echo 0 1 0 $C4topup >> $acqParams
my_do_cmd cat $acqParams



# run topup
echo "  [INFO] Running topup"
my_do_cmd $fake topup -v \
--imain=$b0s_combined \
--datain=$acqParams \
--config=b02b0.cnf \
--out=${outbase}_topup \
--fout=${outbase}_topup_field \
--iout=${outbase}_unwarped_b0images



# create a mask
mask=${outbase}_mask
my_do_cmd fslmaths ${outbase}_unwarped_b0images -Tmean ${tmpDir}/av_b0
my_do_cmd bet ${tmpDir}/av_b0 ${outbase} -m -n -f 0.35


if [[ "$DWI_to_fix" = "$DWI_yPos" ]]
  then
  refIndex=2
  bvals_to_fix=$bvals_yPos
  bvecs_to_fix=$bvecs_yPos
elif [[ "$DWI_to_fix" = "$DWI_yNeg" ]]
  then
  refIndex=1
  bvals_to_fix=$bvals_yNeg
  bvecs_to_fix=$bvecs_yNeg
else
  echo "FATAL ERROR: I cannot repair images $DWI_to_fix
  because it does not match any of the yPos or yNeg inputs. Quitting."
  exit 2
fi

echo "
[INFO] Will fix images $DWI_to_fix
Reference to $acqParams is $refIndex
"


nT=`fslval $DWI_to_fix dim4`
txt_index=${outbase}_indices.txt
indx=""
for ((i=1; i<=$nT; i+=1)); do indx="$indx $refIndex"; done
echo $indx > $txt_index



if [ $doCuda -eq 1 ]
then
  cuda_cmd=eddy_cuda
else
  cuda_cmd=eddy
fi



echo "  [INFO] Running eddy. Go grab a beer and come back later..."
my_do_cmd $fake $cuda_cmd \
--verbose \
--imain=$DWI_to_fix \
--mask=$mask \
--acqp=$acqParams \
--index=$txt_index \
--bvecs=$bvecs_to_fix \
--bvals=$bvals_to_fix \
--topup=${outbase}_topup \
--flm=linear \
--out=${outbase}_corrected


cp -v $bvals_to_fix ${outbase}_corrected.bval
#cp -v $bvecs_to_fix ${outbase}_corrected.bvec


#matlabCMD="rotate_bvecs('$bvecs_to_fix', '${outbase}_corrected.eddy_parameters', '${outbase}_corrected.bvec');exit"


#echo $matlabCMD
#$matlabBIN -nodisplay -nosplash -nojvm -r "$matlabCMD"


if [ $keep_tmp -eq 0 ]
then
  echo "  [INFO] Cleaning up..."
  rm -fRv $tmpDir
fi








# #!/bin/bash
# source `which my_do_cmd`
#
# orig_DTI_up=$1
# orig_DTI_dn=$2
# outbase=$3
#
#
#
# #### DEFAULTS
# index_b0_up=0
# index_b0_dn=0
# tmpDir=/tmp/inb_topup_$$/
# keep_tmp=0
# dwell=1
# bval=`imglob $orig_DTI_up`.bval
# bvec=`imglob $orig_DTI_up`.bvec
# betF=0.4
# #############
#
#
#
#
# print_help()
# {
#   echo "
#   `basename $0` <DTI_up> <DTI_dn> <outbase>
#
# Performs unwarping of a DTI data set based on topup (fsl 5.0).
# Designed for INB files from the Philips.
# IMPORTANT ASSUMPTIONS: DTI_up is the full data set
#                        DTI_dn is a partial data set used only for reverse phased b=0.
#
# DTI_up: A 4D volume including b=0 images that were acquired with a y+
#         phase encoding. These typically look compressed at the frontal lobe.
# DTI_dn: Another 4D volume with b=0 images with identical parameters
#         but with y- phase encoding. These look stretched at the frontal lobes.
# outbase: Stem of outputs. Will create a few.
#
#
# OPTIONS
#
# -index_b0_up :   The index in which the b=0 volume is situated in the 4th dimension.
#
# -index_b0_dn :   The index in which the b=0 volume is situated in the 4th dimension.
#
# -dwell <float> : If provided, the resulting field map will have correct values in Hz.
#                  The dwell time or echo spacing in ms. This is the time
#                  between the centers of two adjacent k-space lines.
#                  see http://www.spinozacentre.nl/wiki/index.php/NeuroWiki:Current_developments
#                  and http://incenter.medical.philips.com/doclib/enc/fetch/2000/4504/3634249/3634100/4987812/5025553/5068598/5529620/FS36_Aptip_BW_WFS.pdf%3fnodeid%3d5529294%26vernum%3d1
#                  and
#                  http://support.brainvoyager.com/functional-analysis-preparation/27-pre-processing/459-epi-distortion-correction-echo-spacing.html
#
#                  In essence:
#                  effective echo spacing = (1000 * wfs) / (FreqOffset * (etl+1) ),
#                  where wfs is water fat shift (can be obtained from .PAR)
#                  FreqOffset is the chemical shift between water and fat (434.215 Hz at 3T)
#                  etl is the echo train lenght (epi factor in .PAR).
#
# -bval <file> : Specify a bval file. Default is \$DTI_up.bval
#
# -bvec <file> : Specify a bvec file. Default is \$DTI_up.bvec
#
# -betF <float> : Specify the value for the fractional intensity
#                 fraction to be used by bet (default is $betF).
#
# -keep_tmp
#
# -tmpDir <path>
#
#
# Example:
# `basename $0` DWI60dir.nii.gz DWI4fmap.nii.gz corrected -index_b0_up 60 -index_b0_dn 1 -dwell 0.7005
#
# see http://fsl.fmrib.ox.ac.uk/fsl/fslwiki/topup/ApplyTopupUsersGuide
#
#   Luis Concha
#   INB, UNAM
#   April 2011
# "
# }
#
#
# if [ $# -lt 2 ]
# then
#   echo " ERROR: Need more arguments..."
#   print_help
#   exit 1
# fi
#
#
#
# declare -i i
# i=1
# skip=1
# hasDwell=0
# for arg in "$@"
# do
#   case "$arg" in
#     -h|-help)
#       print_help
#       exit 1
#     ;;
#     -index_b0_up)
#       nextarg=`expr $i + 1`
#       eval index_b0_up=\${${nextarg}}
#     ;;
#     -index_b0_dn)
#       nextarg=`expr $i + 1`
#       eval index_b0_dn=\${${nextarg}}
#     ;;
#     -tmpDir)
#       nextarg=`expr $i + 1`
#       eval tmpDir=\${${nextarg}}
#     ;;
#     -keep_tmp)
#       keep_tmp=1
#     ;;
#     -dwell)
#       nextarg=`expr $i + 1`
#       eval dwell=\${${nextarg}}
#       hasDwell=1
#     ;;
#     -bval)
#       nextarg=`expr $i + 1`
#       eval bval=\${${nextarg}}
#     ;;
#     -bvec)
#       nextarg=`expr $i + 1`
#       eval bvec=\${${nextarg}}
#     ;;
#     -betF)
#       nextarg=`expr $i + 1`
#       eval betF=\${${nextarg}}
#       hasMask=1
#     ;;
#     esac
#     i=$[$i+1]
# done
#
#
# mkdir $tmpDir
#
#
#
#
# echo "--------------------------"
# echo "  orig_DTI_up  : $orig_DTI_up"
# echo "  index_b0_up  : $index_b0_up"
# echo ""
# echo "  orig_DTI_dn  : $orig_DTI_dn"
# echo "  index_b0_dn  : $index_b0_dn"
# echo ""
# echo "  dwell time   : $dwell ms"
# echo "  bval file    : $bval"
# echo "  bvec file    : $bvec"
# echo "  bet fraction : $betF"
# echo "--------------------------"
#
# nY=`fslinfo $orig_DTI_up | grep ^dim2 | awk '{print $2}'`
# # (assumes phase enconding is the second dimensioN!!!)
#
# if [ $hasDwell -eq 1 ]
# then
#   echo "Using user informed dwell of $dwell"
#   slice_acq_time=$dwell
# else
#   dwell_sec=`echo "$dwell / 1000" | bc -l`
#   slice_acq_time=`echo "$dwell_sec * ($nY-1)" | bc -l`
# fi
#
#
# my_do_cmd fslroi $orig_DTI_up $tmpDir/b0_up $index_b0_up 1
# my_do_cmd fslroi $orig_DTI_dn $tmpDir/b0_dn $index_b0_dn 1
# my_do_cmd fslmerge -t $tmpDir/b0_merged $tmpDir/b0_up $tmpDir/b0_dn
#
# txt_acqparams=${outbase}_acqparams.txt
# echo "0 1 0 $slice_acq_time"  >> $txt_acqparams
# echo "0 -1 0 $slice_acq_time" >> $txt_acqparams
#
#
# cat $txt_acqparams
#
#
# echo "  Running topup..."
# my_do_cmd topup \
#   --imain=$tmpDir/b0_merged \
#   --datain=$txt_acqparams \
#   --config=b02b0.cnf \
#   --out=${outbase} \
#   --iout=${outbase}_images \
#   --verbose
#
#
#
# my_do_cmd fslmaths ${outbase}_images -Tmean $tmpDir/av_b0_corr
# my_do_cmd bet $tmpDir/av_b0_corr ${outbase} -m -f $betF
#
#
# # We create the index file.
# # It refers each volume in the full DTI 4Dvol to the acqparams file.
# # that is, it informs eddy of which phase encoding was used for each frame.
# # Normally this is just the same line number repeated nFrames times.
# # right now, HARD CODED to be the first line, which corresponds to orig_DTI_up
# nT=`fslinfo $orig_DTI_up | grep ^dim4 | awk '{print $2}'`
# txt_index=${outbase}_index.txt
# indx=""
# for ((i=1; i<=$nT; i+=1)); do indx="$indx 1"; done
# echo $indx > $txt_index
#
# echo "  Running eddy. Go grab a beer and come back later..."
# my_do_cmd eddy \
#   --verbose \
#   --imain=${orig_DTI_up} \
#   --mask=${outbase}_mask \
#   --acqp=$txt_acqparams \
#   --index=$txt_index \
#   --bvecs=$bvec \
#   --bvals=$bval \
#   --topup=${outbase} \
#   --flm=linear \
#   --out=${outbase}_corrected
#
# if [ $keep_tmp -eq 0 ]
# then
#   rm -fR $tmpDir
# else
#   echo "Did not remove tmpDir $tmpDir"
# fi
#
