#!/bin/bash


# flip a tract vtk file


print_help()
{
echo "
`basename $0` tractsIN.vtk tractsOUT.vtk image.nii

 Luis Concha
 INB, Oct 2011

"
}



if [ $# -lt 3 ] 
then
	echo " ERROR: Need more arguments..."
	print_help
	exit 1
fi




tractsIN=$1
tractsOUT=$2
image=$3

echo "tractsIN:  $tractsIN"
echo "tractsOUT: $tractsOUT"
echo "image:     $image"


tmpDir=/tmp/$$_flipTract
mkdir $tmpDir

#nii2mnc $image ${tmpDir}/${image%.nii}.mnc

#offset=`mincinfo -attvalue yspace:start ${tmpDir}/${image%.nii}.mnc`


offset=0


nPoints=`grep POINTS $tractsIN | awk '{print $2}'`

from=`grep -n POINTS $tractsIN | awk -F: '{print $1}'`
to=`grep -n LINES $tractsIN | awk -F: '{print $1}'`

tail -n +$(($from + 1)) $tractsIN | head -n $nPoints > ${tmpDir}/coords

# let's see how much we should write to stdout
if [ $nPoints -lt 100 ]
then
    modulator=1
elif [ $nPoints -lt 1000 ]
then
   modulator=10
else
   modulator=100
fi




jobfile=${tmpDir}/jobfile
zoffset=-4


echo "
coords = load('${tmpDir}/coords');
coords(:,2) =  $offset - coords(:,2);
coords(:,2) =  coords(:,2) + $zoffset;
fprintf(1,'The size of coords is %s\n',mat2str(size(coords)));
coords_ifname = '${tmpDir}/coords_i';
fid = fopen(coords_ifname,'w');
fprintf(fid,'%1.4f %1.4f %1.4f\n',coords');
fclose(fid);
" >> $jobfile

cat $jobfile

matlab -nodisplay < $jobfile





# re-assemble the vtk file
echo "Reassembling the vtk file"
head -n $from $tractsIN > $tractsOUT
echo "..."
cat ${tmpDir}/coords_i >> $tractsOUT
echo "..."
tail -n +${to} $tractsIN >> $tractsOUT
echo "Done."



rm -fR $tmpDir