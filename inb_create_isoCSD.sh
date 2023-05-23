#!/bin/bash



origCSD=$1
isoCSD=$2


isLink=0
if [ -h $origCSD ]
then
  isLink=1
  tmpISO=/tmp/isoCSD_$$_`basename $origCSD`
  echo "  file is a sym link: $origCSD"
  cp -v $origCSD $tmpISO
  origCSD=$tmpISO
fi


## make an isotropic CSD
octave --silent --eval "
[hdr,csd] = niak_read_nifti('${origCSD}');
isoCSD = zeros(size(csd));
isoCSD(:,:,:,1) = 1;
hdr.file_name = '$isoCSD';
niak_write_nifti(hdr,single(isoCSD));
"

if [ $isLink -eq 1 ]
then
  rm -v $tmpISO
fi