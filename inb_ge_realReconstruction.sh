#!/bin/bash
source `which my_do_cmd`

# if you set the user CV rhrcctrl=15, then you get the 
# magnigude
# phase
# real
# imaginary 
# images.

# You export all of them to a folder, which is what you input to this function
# In the end you get a real reconstruction


dcmDir=$1
outbase=$2

nFiles=`ls $dcmDir | wc -l`

tmpDir=/tmp/realReconstruction_$$
mkdir $tmpDir
mkdir ${tmpDir}/mnc_a ${tmpDir}/mnc_b ${tmpDir}/mnc_c ${tmpDir}/mnc_d 


mkdir ${tmpDir}/a ${tmpDir}/b ${tmpDir}/c ${tmpDir}/d

for f in `seq 1 4 $nFiles`; do cp ${dcmDir}/`zeropad $f 4`.dcm ${tmpDir}/a/;done
for f in `seq 2 4 $nFiles`; do cp ${dcmDir}/`zeropad $f 4`.dcm ${tmpDir}/b/;done
for f in `seq 3 4 $nFiles`; do cp ${dcmDir}/`zeropad $f 4`.dcm ${tmpDir}/c/;done
for f in `seq 4 4 $nFiles`; do cp ${dcmDir}/`zeropad $f 4`.dcm ${tmpDir}/d/;done

for DIR in a b c d
do
  my_do_cmd dcm2mnc ${tmpDir}/${DIR} ${tmpDir}/mnc_${DIR}
  mv -v ${tmpDir}/mnc_${DIR}/*/*.mnc ${tmpDir}/mincfile_${DIR}.mnc
done

jobfile=${tmpDir}/jobfile

echo "
fname = '${tmpDir}/mincfile_c.mnc';
[hdr,c] = niak_read_minc(fname);
fname = '${tmpDir}/mincfile_d.mnc';
[hdr,d] = niak_read_minc(fname);


REALvolume = zeros(size(c));
PMAP       = zeros(size(c));
for slice = 1 : size(c,3)
  s_c = c(:,:,slice);
  s_d = d(:,:,slice);
  Com = complex(s_c,s_d);
  [img2,pmap] = realrec(Com);
  REALvolume(:,:,slice) = img2;
  PMAP(:,:,slice) = pmap;
end


hdr.file_name = '${outbase}_realRec.mnc'; 
niak_write_minc(hdr,REALvolume);
hdr.file_name = '${outbase}_pmap.mnc'; 
niak_write_minc(hdr,PMAP);

" > $jobfile

cat $jobfile

matlab -nodisplay < $jobfile



rm -fR $tmpDir


