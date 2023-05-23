#!/bin/bash
source `which  my_do_cmd`

# prepare the data pertaining the parkinson-SLP protocol for processing with mrtrix.

DWI4fmap=$1
b2000_A=$2
b2000_B=$3
b2000_C=$4
outbase=$5


#dwell=0.654629619
#dwell = (1000 * wfs) / (FreqOffset * (etl+1) )
wfs=`grep "Water Fat" $b2000_A | awk -F: '{print $2}' | sed 's/ //g' | strings`
FreqOffset=434.215
etl=`grep "EPI factor" $b2000_A | awk -F: '{print $2}' | sed 's/ //g' | sed 's/[^a-z|0-9]//g'`
numerator=`echo "1000 * $wfs" | bc -l`
denominator=`echo "$FreqOffset * $(($etl+1))" | bc -l`
dwell=`echo "$numerator / $denominator" | bc -l`



if [ ${#dwell} -eq 0 ]
then
  echo "Could not calculate dwell time. Quitting now"
  exit 2
else
  echo "  [INFO] Dwell = $dwell"
fi


par2nii=PARconv_v1.12.sh

my_do_cmd $par2nii $DWI4fmap ${outbase}_DWI4fmap.nii.gz
my_do_cmd $par2nii $b2000_A ${outbase}_b2000_A.nii.gz
my_do_cmd $par2nii $b2000_B ${outbase}_b2000_B.nii.gz
my_do_cmd $par2nii $b2000_C ${outbase}_b2000_C.nii.gz






mv -v ${outbase}_DWI4fmap_bvals.txt ${outbase}_DWI4fmap.bval
mv -v ${outbase}_b2000_A_bvals.txt ${outbase}_b2000_A.bval
mv -v ${outbase}_b2000_B_bvals.txt ${outbase}_b2000_B.bval
mv -v ${outbase}_b2000_C_bvals.txt ${outbase}_b2000_C.bval

mv -v ${outbase}_DWI4fmap_bvecs.txt ${outbase}_DWI4fmap.bvec
mv -v ${outbase}_b2000_A_bvecs.txt ${outbase}_b2000_A.bvec
mv -v ${outbase}_b2000_B_bvecs.txt ${outbase}_b2000_B.bvec
mv -v ${outbase}_b2000_C_bvecs.txt ${outbase}_b2000_C.bvec


# remove emtpy lines
for bfile in ${outbase}_*.bv??
do
  sed -i '/^$/d' $bfile
done



my_do_cmd fslmerge -t \
  ${outbase}_DWI_all.nii.gz \
  ${outbase}_b2000_A.nii.gz \
  ${outbase}_b2000_B.nii.gz \
  ${outbase}_b2000_C.nii.gz
  
cat ${outbase}_b2000_A.bvec \
      ${outbase}_b2000_B.bvec \
      ${outbase}_b2000_C.bvec \
      > ${outbase}_DWI_all.bvec

cat ${outbase}_b2000_A.bval \
      ${outbase}_b2000_B.bval \
      ${outbase}_b2000_C.bval \
      > ${outbase}_DWI_all.bval



my_do_cmd inb_topup.sh \
    ${outbase}_DWI_all.nii.gz \
    ${outbase}_DWI4fmap.nii.gz \
    $outbase \
    -index_b0_up 32 \
    -index_b0_dn 1 \
    -dwell $dwell \
    -bval ${outbase}_DWI_all.bval \
    -bvec ${outbase}_DWI_all.bvec \
    -betF 0.35