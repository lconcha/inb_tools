#!/bin/bash



print_help()
{
  echo "
  `basename $0` <IN.nii.gz> <seed.nii.gz> <OUT.nii.gz>

  Region-grow a particular region. 
  Useful for making masks of pseudo-clusters out of uncorrected, thresholded, p-value maps.

  Seed is a SINGLE VOXEL binary mask from where to start the region growing. Of course,
    it must be exactly the same dimensions as IN.
  
  Note that the IN file will be binarized in the process.

  
  
  Luis Concha
  INB
  2012
  lconcha@unam.mx
"
}



if [ $# -lt 3 ] 
then
  echo "  ERROR: Need more arguments..."
  print_help
  exit 1
fi


IN=$1
seed=$2
OUT=$3



tmpDir=/tmp/floodfill_$$
mkdir $tmpDir


fslmaths $IN -bin ${tmpDir}/IN.nii.gz
IN=${tmpDir}/IN.nii.gz


############# CALL MATLAB
matlab -nodisplay << EOF
fIN = '$IN';
fOUT = '$OUT';
fSeed = '$seed';

fprintf(1,'Loaded files:\n  %s\n  %s\n',fIN,fSeed);


[hdr_IN,IN]       = niak_read_nifti(fIN);
[hdr_SEED,seed]   = niak_read_nifti(fSeed);
hdr_OUT           = hdr_SEED;
hdr_OUT.file_name = fOUT

index = find(seed(:)>0);
if length(index) > 1
  index     = index(1);
end

[r,c,s] = ind2sub(size(seed),index);
[p,OUT] = regionGrowing(IN,[r c s]);

fprintf(1,'Now writing to %s\n',fOUT);
niak_write_nifti(hdr_OUT,int16(OUT));
fprintf(1,'Done.\n\n\n');
EOF
################## END MATLAB

rm -fR $tmpDIr
