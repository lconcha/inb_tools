#!/bin/bash

dwi=$1
grad=$2
outbase=$3




#### Defaults
est_lmax=6
lmax=10
mask=${outbase}_mask.nii
max_iter=10
#############


print_help()
{
echo "
`basename $0` <dwi.[mif|nii]> <grad.b> <outbase> [-OPTIONS]

 Options:
 -est_lmax <integer>    Maximum harmonic for estimating the response function
                        (Default = ${est_lmax} )
 -lmax <integer>        Maximum harmonic for estimating the response function 
                        (Default = ${lmax} )
 -mask <mask.mif>       Restrict the analysis to this mask.
                        If not used, then a mask will be created using bet.
 -noCSD                 Do not do anything related to constrained spherical deconvolution.
 -normalise             Normalise the DW signal to the b=0 image.
 -nii                   Use NIFTI for output, instead of .mif (.mif is default).
 -niigz 		Use Compressed NIFTI for output.
 -tensor_metrics        Output more tensor metrics (eigenvalues and first eigenvector)
 -ratios                Divide each volume in dwi by the average b=0 volume.
                        This is done before doing CSD, and ignored for the DTI part.
                        Useful for getting a response function that is similar between subjects. 
 -robust_response <max_iter>   Perform an iterative estimation of the response function,
                        until it is most certain that it comes from a single fibre population. [1]
                        max_iter: maximum iterations if convergence is not reached.
                        Currently set to $max_iter.
 -response <response.txt> Provide the response function.
 -fixWrongCSD           Remove voxels with unusually large first component of CSD coefficent.
                        Uses the robust intensity range of the first volume of CSD.
                        Will produce another CSD file with _fixed suffix.

 All these steps are neatly described here:
 http://www.brain.org.au/software/mrtrix/tractography/preprocess.html

 [1] Inspired by Tax et al., Neuroimage 2013

 Luis Concha
 INB, Jan 2011

"
}



if [ $# -lt 3 ] 
then
	echo " ERROR: Need more arguments..."
	print_help
	exit 1
fi


normalise=""
doCSD=1
suffix=mif
robust_response=0
hasResponse=0
do_tensor_metrics=0
do_ratios=0
fixWrongCSD=0
declare -i i
i=1
for arg in "$@"
do
  case "$arg" in
  -h|-help) 
    print_help
    exit 1
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
  -noCSD)
    doCSD=0
  ;;
  -normalise)
    normalise="-normalise"
  ;;
  -nii)
    suffix=nii
  ;;
  -niigz)
    suffix=nii.gz
  ;;
  -tensor_metrics)
    do_tensor_metrics=1
  ;;
  -robust_response)
    robust_response=1
    nextarg=`expr $i + 1`
    eval max_iter=\${${nextarg}}
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
  esac
  i=$[$i+1]
done

uname -a

echo "Suffix is $suffix" 
# Check that we have a recent version that can write nii.gz files
VersionA=`dwi2tensor -version | head -n 1 | awk '{print $2}' | awk -F. '{print $1}'`
VersionB=`dwi2tensor -version | head -n 1 | awk '{print $2}' | awk -F. '{print $2}'`
VersionC=`dwi2tensor -version | head -n 1 | awk '{print $2}' | awk -F. '{print $3}'`
if [[ "$suffix" == "nii.gz" ]]
then
  if [ $VersionB -gt 1 -a $VersionC -gt 10 ]
  then
      echo "Found mrtrix version $VersionA.$VersionB.$VersionC"
  else
      echo "Cannot save compressed NIFTI files with the current version ($VersionA.$VersionB.$VersionC) "
      echo "You can save NIFTI files by using the -nii switch or the default .mif files. Quitting."
      exit 1
  fi
fi



# Make a temp directory
tmpDir=/tmp/mrtrix_proc_$$
mkdir $tmpDir



IS_GZ=0
if [ ${dwi##*.} == "gz" ]
then
  ff=`basename $dwi`
  echo "File $dwi is a gzipped file"
  IS_GZ=1
  gunzip -v -c $dwi > ${tmpDir}/${ff%.gz}
  dwi=${tmpDir}/${ff%.gz}
  echo "The DWI has been set to its decompressed version: $dwi"
fi  






# create a brain mask
if [ -f $mask ]
then
	echo "Found mask: $mask"
else
	echo "Did not find a mask."
	# mrconvert $dwi -coord 3 0 - | threshold - - | median3D - - | median3D - $mask
	echo "Generating a bet mask"
	mrconvert $dwi -coord 3 0 ${tmpDir}/b0.nii
	#mrconvert ${tmpDir}/b0.${suffix} ${tmpDir}/b0.nii
	FSLOUTPUTTYPE=NIFTI
	bet ${tmpDir}/b0.nii ${tmpDir}/b0 -m -n -f 0.15
	mrconvert ${tmpDir}/b0_mask.nii $mask	
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
  dwi2tensor $dwi -grad $grad $dt
fi
if [ -f ${outbase}_fa.${suffix} ]
then
  echo "Found ${outbase}_fa.${suffix} (not overwriting)"
else
  tensor2FA $dt - | mrmult - $mask ${outbase}_fa.${suffix}
fi
if [ -f ${outbase}_ev.${suffix} ]
then
  echo "Found ${outbase}_ev.${suffix} (not overwriting)"
else
  tensor2vector $dt - | mrmult - ${outbase}_fa.${suffix} ${outbase}_ev.${suffix}
fi
if [ -f ${outbase}_adc.${suffix} ]
then
  echo "Found ${outbase}_adc.${suffix} (not overwriting)"
else
  tensor2ADC $dt - | mrmult - $mask ${outbase}_adc.${suffix}
fi


if [ $do_tensor_metrics -eq 1 ]
then
  for v in 1 2 3
  do
    if [ -f ${outbase}_l${v}.${suffix} ]
    then
      echo "Found ${outbase}_l${v}.${suffix} (not overwriting)"
    else
      tensor_metric -num ${v} -value - -mask $mask $dt | mrmult - $mask ${outbase}_l${v}.${suffix}
    fi
  done
  if [ -f ${outbase}_v1.${suffix} ]
  then
     echo "Found $mask ${outbase}_v1.${suffix} (not overwriting)"
  else
    tensor_metric -num 1 -vector - -mask $mask $dt | mrmult - $mask ${outbase}_v1.${suffix}
  fi
fi






###########################################
#                    CSD                  #
###########################################
if [ $doCSD -eq 1 ]
then

  if [ $do_ratios -eq 1 ]
  then
    echo " INFO: Obtaining the ratios of DWIs to the average b=0 volume..."
    inb_DWI_b0_ratios.sh $dwi $grad ${outbase}_dwi_ratios.${suffix}
    dwi=`imfullname ${outbase}_dwi_ratios`
  fi

  #### Robust estimation of response function
  if [ $robust_response -eq 1 -a $hasResponse -eq 0 ]
  then
    echo " Entering iterative loop"
    inb_mrtrix_responseFunction_iter.sh \
      $dwi \
      $grad \
      $mask \
      ${outbase}_fa.${suffix} \
      0.7 \
      ${outbase}_response.txt \
      ${outbase}_sf.${suffix} \
      -max_iter $max_iter
  fi
  #### end robust estimation of response function


  # make mask of single fibre voxels
  if [ ! -f ${outbase}_sf.${suffix} ]
  then
    #erode $mask - | erode - - | mrmult ${outbase}_fa.${suffix} - - | threshold - -abs 0.6 ${outbase}_sf.${suffix}
  erode -npass 2 $mask ${tmpDir}/tmp.${suffix}
  mrmult ${outbase}_fa.${suffix} ${tmpDir}/tmp.${suffix} ${tmpDir}/tmp2.${suffix}
  threshold ${tmpDir}/tmp2.${suffix} -abs 0.6 ${outbase}_sf.${suffix}  
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
	  if [ $robust_response -eq 1 ]
          then
	     echo "THe robust estimation of response function failed. Bailing out."
	     exit 2
             rm -fR $tmpDir
	  fi 

          echo "Estimating response function with est_lmax of $est_lmax"
	  echo "  estimate_response $dwi ${outbase}_sf.${suffix} -grad $grad -lmax $est_lmax $response"
	  estimate_response $dwi ${outbase}_sf.${suffix} -grad $grad -lmax $est_lmax $response
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
    echo "  csdeconv $dwi -grad $grad $response -lmax $lmax -mask $mask ${outbase}_CSD${lmax}.${suffix}"
    time csdeconv $dwi -grad $grad $response $normalise -lmax $lmax -mask $mask ${outbase}_CSD${lmax}.${suffix}
  else
    echo "Found ${outbase}_CSD${lmax}.${suffix} (Not overwriting)"
  fi


  # Generation of white matter mask
  wm_mask_prob=${outbase}_wmMask_prob.${suffix}
  wm_mask=${outbase}_wmMask.${suffix}
  if [ ! -f $wm_mask ]
  then
    gen_WM_mask $dwi -grad $grad $mask $wm_mask_prob
    threshold $wm_mask_prob $wm_mask -abs 0.4
  else
    echo "Found $wm_mask (not overwriting)"
  fi

  if [ $fixWrongCSD -eq 1 ]
  then
    echo "Removing potentially wrong CSD estimations"
    mrconvert -coord 3 0 ${outbase}_CSD${lmax}.${suffix} ${tmpDir}/first.nii
    upperLimit=`fslstats ${tmpDir}/first.nii -k $mask -r | awk '{print $2}'`
    threshold ${tmpDir}/first.nii -abs $upperLimit -invert - | mrmult - $mask ${tmpDir}/CSDmask.nii
    mrmult ${tmpDir}/CSDmask.nii ${outbase}_CSD${lmax}.${suffix} ${outbase}_CSD${lmax}_fixed.${suffix}
    #mv -v ${outbase}_CSD_fixed${lmax}.${suffix} ${outbase}_CSD${lmax}.${suffix}
  fi

fi


# clean up
rm -fR $tmpDir



