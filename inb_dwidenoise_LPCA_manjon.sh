#!/bin/bash

dwiOrig=$1
outbase=$2


factor=1
correlation=1; % 1: correlated noise 0: white noise
rician=1;      % 1 for bias correction and 0 to disable it.
matlabCMD=/home/inb/lconcha/fmrilab_software/tools/fmrilab_matlab16.sh

print_help()
{
  
 echo "

  `basename $0` <dwioriginal.nii> <outbase> [Options]

Use LPCA denoising as implemented by Manjón & Coupé in Matlab.
This is just a wrapper for DWIDenoisingLPCA.m

Options

-factor <float>              Default is 1.0
-correlation <1|0>           Default is 1. Use this for DWIs acquired with multiple channels.
-rician <1|0> Default is 1.  Estimate rician noise bias.
-matlabCMD </path/to/matlab/executable> Default is $matlabCMD

LU15 (0N(H4
lconcha@unam.mx
INB, UNAM
May, 2017
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
inversions='[1 1 1]'
write_nifti=true
for arg in "$@"
do
  case "$arg" in
  -h|-help) 
    print_help
    exit 1
  ;;
  -factor)
    nextarg=`expr $i + 1`
    eval factor=\${${nextarg}}
  ;;
-correlation)
    nextarg=`expr $i + 1`
    eval correlation=\${${nextarg}}
  ;;
-rician)
    nextarg=`expr $i + 1`
    eval rician=\${${nextarg}}
  ;;
-matlabCMD)
    nextarg=`expr $i + 1`
    eval matlabCMD=\${${nextarg}}
  ;;
  esac
  i=$[$i+1]
done

echo "
  Arguments for DWIDenoisingLPCA.m 
    factor  (default is 1)    : $factor
    correlation  (correlated noise, as in SENSE = 1, else 0)  : $correlation
    rician  (rician noise = 1, else 0)   : $rician   
    matlabCMD   : $matlabCMD
"



$matlabCMD -nodisplay <<EOF     
%%%%%%%%%%%%%%%%%%%%5
warning off
addpath(genpath('/misc/mansfield/lconcha/software/DWIDenoisingPackage_r01_pcode'))
nbthread = maxNumCompThreads*2; % INTEL with old matlab
    
% read the data
fprintf(1,'Will now read the file: %s\n','${dwiOrig}')
V   = spm_vol('${dwiOrig}');
ima = spm_read_vols(V);

% filter the data        
[fima,map] = DWIDenoisingLPCA(ima, $rician, nbthread,$factor,$correlation);

% save result 
ss=size(V);
for ii=1:ss(1)
  V(ii).fname='${outbase}_dwiDenoised.nii';
  spm_write_vol(V(ii),fima(:,:,:,ii));
end

for ii=1:ss(1)
  V(ii).fname='${outbase}_residuals.nii';
  spm_write_vol(V(ii),ima(:,:,:,ii)-fima(:,:,:,ii));
end

%noise    
for ii=1:1
  V(ii).fname='${outbase}_noise.nii';
  V(ii).dim=size(map);
  spm_write_vol(V(ii),map);
end
%%%%%%%%%%%%%%%%%%%%%%%%%5
EOF
    

