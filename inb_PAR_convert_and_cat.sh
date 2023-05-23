#!/bin/bash
source `which my_do_cmd`


help()
{
echo "
`basename $0` <output.mif> <input_0.PAR> [input_1.PAR] [... input_n.PAR]

Note: This script uses PARconv_v1.12.sh and will fantastically fail if it is not in your PATH.
Note2:  All images must have the same dimensions, or they will not concatenate properly.

 LU15 (0N(H4
 INB, UNAM
 Oct 2016.
 lconcha@unam.mx

"
}

if [ $# -lt 2 ]
  then
  echo " ERROR: Need more arguments..."
  help
  exit 1
fi





output=$1
shift


tmpDir=/tmp/PARconv_$$
mkdir $tmpDir

i=0
for f in $@
do
  ii=`zeropad $i 3`
  #echo $i $f
  my_do_cmd PARconv_v1.12.sh $f ${tmpDir}/${ii}.nii.gz
  i=$[$i+1]
done

for f in ${tmpDir}/*_bv??s.txt
do
   sed -i '/^$/d' $f
   echo .
done

cat ${tmpDir}/*_bvals.txt > ${tmpDir}/bval
cat ${tmpDir}/*_bvecs.txt > ${tmpDir}/bvec


gunzip -v ${tmpDir}/*.nii.gz

nFiles=`ls ${tmpDir}/*.nii | wc -l`

if [ $nFiles -gt 1 ]
then
  mrcat ${tmpDir}/*.nii ${tmpDir}/HARDI.mif
else
  mrconvert ${tmpDir}/*.nii ${tmpDir}/HARDI.mif
fi


paste ${tmpDir}/bvec  ${tmpDir}/bval > ${tmpDir}/b
awk '{print $1,-$2,-$3,$4}' ${tmpDir}/b > ${tmpDir}/bflip


my_do_cmd mrconvert -grad ${tmpDir}/bflip ${tmpDir}/HARDI.mif $output


rm -fR $tmpDir
 



# tmpDir=/tmp/gaby_convert_$$
# 
# mkdir $tmpDir
# 
# 
# PARconv_v1.12.sh $A ${tmpDir}/b1000A.nii.gz
# PARconv_v1.12.sh $B ${tmpDir}/b2000B.nii.gz
# PARconv_v1.12.sh $C ${tmpDir}/b2000C.nii.gz
# PARconv_v1.12.sh $D ${tmpDir}/b2000D.nii.gz
# 
# for f in ${tmpDir}/*_bv??s.txt
# do
#    sed -i '/^$/d' $f
#    echo .
# done
# 
# cat ${tmpDir}/b1000A_bvals.txt \
#     ${tmpDir}/b2000B_bvals.txt \
#     ${tmpDir}/b2000C_bvals.txt \
#     ${tmpDir}/b2000D_bvals.txt > ${tmpDir}/bval
# 
# cat ${tmpDir}/b1000A_bvecs.txt \
#     ${tmpDir}/b2000B_bvecs.txt \
#     ${tmpDir}/b2000C_bvecs.txt \
#     ${tmpDir}/b2000D_bvecs.txt > ${tmpDir}/bvec
# 
# paste ${tmpDir}/bvec  ${tmpDir}/bval > ${tmpDir}/b
# 
# mrcat ${tmpDir}/b1000A.nii.gz \
#       ${tmpDir}/b2000B.nii.gz \
#       ${tmpDir}/b2000C.nii.gz \
#       ${tmpDir}/b2000D.nii.gz \
#       ${tmpDir}/HARDI.mif
# 
# awk '{print $1,-$2,-$3,$4}' ${tmpDir}/b > ${tmpDir}/bflip
# 
# mrconvert -grad ${tmpDir}/bflip ${tmpDir}/HARDI.mif ${output}.mif
# 
# 
# rm -fR $tmpDir
