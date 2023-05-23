#!/bin/bash
source `which my_do_cmd`

tarfile=$1
outfile=$2

echoesTXT=/home/inb/lconcha/Philips_ProtocoloEpilepsia_T2relaxo_echoes.txt

tmpDir=/tmp/T2_$$
mkdir $tmpDir


echo "Decompressing file $tarfile ..." 
tar --verbose \
  --extract \
  --file=$tarfile \
  --wildcards '*_T2_*' | tee $tmpDir/output.txt

isPAR=`grep .PAR $tmpDir/output.txt`


if [ -z "${isPAR}" ]
then
  isDicom=1
else
  isDicom=0
fi



if [ $isDicom -eq 0 ]
then
  PARfile=`grep .PAR $tmpDir/output.txt`
  RECfile=${PARfile%.PAR}.REC
  echo PARfile: $PARfile 
  my_do_cmd dcm2nii -r n -x n -o ${tmpDir} $PARfile
  rm -v $PARfile $RECfile
  #NIIfile=`ls $tmpDir/2*calc_MSCLEAR*001x9.nii.gz`
  #my_do_cmd mv -v $NIIfile $outfile
  my_do_cmd mrcat -axis 3 $tmpDir/2*calc_MSCLEAR*001x[2-8].nii.gz $tmpDir/echoes.nii
  my_do_cmd inb_t2map.sh $tmpDir/echoes.nii $outfile $echoesTXT 100
else
  DICOMdir=`ls -dart * | tail -n 1`
  echo "will convert a dicom dir $DICOMdir"
  my_do_cmd dcm2nii -o $tmpDir $DICOMdir
  T2map=`ls -art ${tmpDir}/*.nii.gz | tail -n 1`
  mv -v $T2map $outfile
  rm -fR $DICOMdir
fi


rm -fR $tmpDir