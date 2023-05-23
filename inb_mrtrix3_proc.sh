#!/bin/bash
source `which my_do_cmd`

dwi=$1
grad=$2
outbase=$3


if [ -z `which tckgen` ]
  then
  echo "ERROR: mrtrix3 not setup. Bye."
  exit 2
fi



#### Defaults
est_lmax=6
lmax=6
mask=${outbase}_mask.nii
normalise=""
doCSD=1
suffix=nii
robust_response=0
hasResponse=0
do_tensor_metrics=0
do_ratios=0
fixWrongCSD=0
findShell=1
fa_sf_thresh=0.6
tensor_method=loglinear
#############



print_help()
{
echo "
`basename $0` <dwi.[mif|nii|nii.gz]> <grad.b> <outbase> [-OPTIONS]

 Options:
 -shell <value>         Use this shell for CSD (only applies to multi-shell data)
                        Default is to use the maximum shell found in gradient list.
 -est_lmax <integer>    Maximum harmonic for estimating the response function
                        (Default = ${est_lmax} )
 -lmax <integer>        Maximum harmonic for estimating the response function
                        (Default = ${lmax} )
 -mask <mask.mif>       Restrict the analysis to this mask.
                        If not used, then a mask will be created using bet.
 -noCSD                 Do not do anything related to constrained spherical deconvolution.
 -normalise             Normalise the DW signal to the b=0 image.
 -mif                   Use mif format for output (.$suffix is default).
 -niigz 		Use Compressed NIFTI for output.
 -tensor_metrics        Output more tensor metrics (eigenvalues and first eigenvector)
 -tensor_method         Use a specific tensor estimation method. 
                        These are passed to dwi2tensor, and options are:
                        loglinear, nonlinear, sech, rician. Default: $tensor_method
 -ratios                Divide each volume in dwi by the average b=0 volume.
                        This is done before doing CSD, and ignored for the DTI part.
                        Useful for getting a response function that is similar between subjects.
 -response <response.txt> Provide the response function.
 -fixWrongCSD           Remove voxels with unusually large first component of CSD coefficent.
                        Uses the robust intensity range of the first volume of CSD.
                        Will produce another CSD file with _fixed suffix.
 -fa_sf_thresh <float>  Pass a different FA threshold for computing 
                        initial single fibre mask. Default is $fa_sf_thresh

 Luis Concha
 INB, May 2015

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
for arg in "$@"
do
  case "$arg" in
  -h|-help)
    print_help
    exit 1
  ;;
  -shell)
    nextarg=`expr $i + 1`
    eval shell=\${${nextarg}}
    findShell=0
  ;;
  -est_lmax)
    nextarg=`expr $i + 1`
    eval est_lmax=\${${nextarg}}
  ;;
  -lmax)
    nextarg=`expr $i + 1`
    eval lmax=\${${nextarg}}
  ;;
  -mask)
    nextarg=`expr $i + 1`
    eval mask=\${${nextarg}}
    echo "Mask provided: $mask"
  ;;
  -tensor_method)
    nextarg=`expr $i + 1`
    eval tensor_method=\${${nextarg}}
    echo "Tensor method: $tensor_method"
  ;;
  -noCSD)
    doCSD=0
  ;;
  -normalise)
    normalise="-normalise"
  ;;
  -mif)
    suffix=mif
  ;;
  -niigz)
    suffix=nii.gz
  ;;
  -tensor_metrics)
    do_tensor_metrics=1
  ;;
  -response)
    hasResponse=1
    nextarg=`expr $i + 1`
    eval response=\${${nextarg}}
    echo "Response function provided: $response"
  ;;
  -ratios)
    do_ratios=1
  ;;
  -fixWrongCSD)
    fixWrongCSD=1
  ;;
  -fa_sf_thresh)
    nextarg=`expr $i + 1`
    eval fa_sf_thresh=\${${nextarg}}
    echo "Provided FA threshold for sf mask: $fa_sf_thresh"
  ;;
  esac
  i=$[$i+1]
done

uname -a

echo "Suffix is $suffix"

# Make a temp directory
tmpDir=/tmp/`whoami`_mrtrix3_proc_$$
mkdir $tmpDir




# create a brain mask
if [ -f $mask ]
then
	echo "Found mask: $mask"
else
	echo "Did not find a mask."
	# mrconvert $dwi -coord 3 0 - | threshold - - | median3D - - | median3D - $mask
	echo "Generating a bet mask"
	my_do_cmd dwiextract -grad $grad -bzero $dwi ${tmpDir}/tmp.nii
  my_do_cmd mrmath -axis 3 ${tmpDir}/tmp.nii mean ${tmpDir}/b0.nii
	FSLOUTPUTTYPE=NIFTI
  my_do_cmd bet ${tmpDir}/b0.nii ${tmpDir}/b0 -m -n -f 0.15
  my_do_cmd mrconvert ${tmpDir}/b0_mask.nii $mask
fi



# create a file where we will keep parameters
paramFile=${outbase}_params.txt
if [ -f $paramFile ]
then
  prev_est_lmax=`grep "param est_lmax" $paramFile | awk '{print $NF}'`
  prev_lmax=`grep "param lmax" $paramFile | awk '{print $NF}'`
  echo "
  Attention: This script has been called before on this file.
             Previous parameters were:
             lmax     = $prev_lmax
             est_lmax = $prev_est_lmax"
else
  touch $paramFile
fi
echo "$0 $@" > $paramFile
echo "param est_lmax $est_lmax" >> $paramFile
echo "param lmax $lmax" >> $paramFile



# compute tensor components
dt=${outbase}_dt.${suffix}
if [ -f $dt ]
then
  echo "Found $dt (not overwriting)"
else
  my_do_cmd dwi2tensor -grad $grad -method $tensor_method $dwi $dt
fi
if [ -f ${outbase}_fa.${suffix} ]
then
  echo "Found ${outbase}_fa.${suffix} (not overwriting)"
else
  my_do_cmd tensor2metric -mask $mask -fa ${outbase}_fa.${suffix} $dt
fi
if [ -f ${outbase}_ev.${suffix} ]
then
  echo "Found ${outbase}_ev.${suffix} (not overwriting)"
else
  my_do_cmd tensor2metric -mask $mask -vector ${outbase}_ev.${suffix}  $dt
fi
if [ -f ${outbase}_adc.${suffix} ]
then
  echo "Found ${outbase}_adc.${suffix} (not overwriting)"
else
  my_do_cmd tensor2metric -mask $mask -adc ${outbase}_adc.${suffix} $dt
fi




if [ $do_tensor_metrics -eq 1 ]
then
  for v in 1 2 3
  do
    if [ -f ${outbase}_l${v}.${suffix} ]
    then
      echo "Found ${outbase}_l${v}.${suffix} (not overwriting)"
    else
      my_do_cmd tensor2metric -num ${v} \
                -value ${outbase}_l${v}.${suffix} \
                -mask $mask $dt
    fi

    if [ -f ${outbase}_v${v}.${suffix} ]
    then
      echo "Found ${outbase}_v${v}.${suffix} (not overwriting)"
    else
      my_do_cmd tensor2metric -num ${v} \
                -vector ${outbase}_v${v}.${suffix} \
                -mask $mask $dt
    fi
  done
fi







###########################################
#                    CSD                  #
###########################################
if [ $doCSD -eq 1 ]
then

  if [ $findShell -eq 1 ]
    then
    shell=`awk 'BEGIN {max = 0} {if ($4>max) max=$4} END {print max}' $grad`

  fi
  echo "[INFO] Shell is $shell"


  # if [ $do_ratios -eq 1 ]
  # then
  #   echo " INFO: Obtaining the ratios of DWIs to the average b=0 volume..."
  #   inb_DWI_b0_ratios.sh $dwi $grad ${outbase}_dwi_ratios.${suffix}
  #   dwi=`imfullname ${outbase}_dwi_ratios`
  # fi


  # make mask of single fibre voxels
  if [ ! -f ${outbase}_sf.${suffix} ]
  then
    #erode $mask - | erode - - | mrmult ${outbase}_fa.${suffix} - - | threshold - -abs 0.6 ${outbase}_sf.${suffix}
  my_do_cmd maskfilter -npass 2 $mask erode ${tmpDir}/tmpmask.nii
  my_do_cmd mrcalc ${tmpDir}/tmpmask.nii \
                   ${outbase}_fa.${suffix} \
                   -mult ${tmpDir}/tmpmask2.nii
  my_do_cmd mrthreshold -abs $fa_sf_thresh ${tmpDir}/tmpmask2.nii ${outbase}_first_sf.${suffix}
  else
    echo "found ${outbase}_sf.${suffix} (not overwriting)"
  fi


  if [ $hasResponse -eq 0 ]
  then
      response=${outbase}_response.txt
  else
      echo "Using previously provided response: $response"
  fi


  if [ -f $response ]
  then
	  echo "Found $response (not overwriting)"
	  if [ -f $paramFile ]
	  then
	      prev_est_lmax=`grep "param est_lmax" $paramFile | awk '{print $NF}'`
              prev_lmax=`grep "param lmax" $paramFile | awk '{print $NF}'`
              if [ $prev_est_lmax -lt $lmax ]
	      then
		 echo "Error. Previous response estimation exists,
			       but it is of lower order ($prev_est_lmax) than currently desired CSD ($lmax).
			       Please delete $response and try again. Bye."
		 exit 2
	      fi
	  fi
  else

   echo "Estimating response function with est_lmax of $est_lmax"
   my_do_cmd dwi2response -grad $grad \
                -mask ${outbase}_first_sf.${suffix} \
                -sf ${outbase}_sf.${suffix} \
                -shell $shell \
                $dwi $response
  fi

  if [ ! -f $response ]
  then
    echo "Fatal error: Did not find file $response"
    exit 2
  fi

  if [ -z "`grep nan $response`" ]
  then
    echo "Response function seems OK:"
    cat $response
  else
    echo "FAILED to compute the response function. Cannot compute CSD, bye."
    echo Response is: `cat $response`
    exit 2
  fi


  # CSD computation
  if [ ! -f ${outbase}_CSD${lmax}.${suffix} ]
  then
    echo "Calculating CSD with lmax of $lmax"
    my_do_cmd dwi2fod \
       -shell $shell \
       -grad $grad  \
       $normalise -lmax $lmax \
       -mask $mask \
       $dwi $response ${outbase}_CSD${lmax}.${suffix}
  else
    echo "Found ${outbase}_CSD${lmax}.${suffix} (Not overwriting)"
  fi

fi


# clean up
rm -fR $tmpDir
