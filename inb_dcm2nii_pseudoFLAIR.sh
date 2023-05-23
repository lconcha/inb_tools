#!/bin/bash
source `which my_do_cmd`

DICOMdir=$1
NIFTIout=$2


print_help()
{
  echo "
  `basename $0` <DICOMdir> <NIFTIout>

  No es necesario poner .nii.gz en NIFTIout.

    AGUAS: Este script es solo válido para el protocolo de epilepsia, 
	  particularmente la secuencia Pseudo-FLAIR-DTI.

  Luis Concha
  INB, UNAM
  April 2013			
"
}


if [ $# -lt 2 ] 
then
  echo " ERROR: Need more arguments..."
  print_help
  exit 1
fi

tmpDir=/tmp/pseudoFlair_$$
mkdir $tmpDir

my_do_cmd inb_dcm2nii.sh $DICOMdir ${tmpDir}/dti

idx_avDWI_b1000=33
should_have_nDim4=66
nDWIdirections=32
nDim4=`fslinfo ${tmpDir}/dti | grep ^dim4 | awk '{print $2}'`

if [ $nDim4 -ne $should_have_nDim4 ]
then
  echo "
  AGUAS: Este script es solo válido para el protocolo de epilepsia, 
	  particularmente la secuencia Pseudo-FLAIR-DTI.
  "
fi


b0=${tmpDir}/b0
b1000=${tmpDir}/b1000
b2000=${tmpDir}/b2000

my_do_cmd fslroi ${tmpDir}/dti $b0 0 1
my_do_cmd fslroi ${tmpDir}/dti $b1000 1 $nDWIdirections
my_do_cmd fslroi ${tmpDir}/dti $b2000 $(($idx_avDWI_b1000 +1)) $nDWIdirections

my_do_cmd fslmerge -t $NIFTIout $b0 $b1000 $b2000

transpose_table.sh ${tmpDir}/dti.bval | head -n $(($nDWIdirections +1)) > $tmpDir/t_bval_0_1000
transpose_table.sh ${tmpDir}/dti.bval | tail -n $nDWIdirections > $tmpDir/t_bval_2000
cat $tmpDir/t_bval_0_1000 $tmpDir/t_bval_2000 > $tmpDir/t_bval_full
transpose_table.sh $tmpDir/t_bval_full > ${NIFTIout}.bval

transpose_table.sh ${tmpDir}/dti.bvec | head -n $(($nDWIdirections +1)) > $tmpDir/t_bvec_0_1000
transpose_table.sh ${tmpDir}/dti.bvec | tail -n $nDWIdirections > $tmpDir/t_bvec_2000
cat $tmpDir/t_bvec_0_1000 $tmpDir/t_bvec_2000 > $tmpDir/t_bvec_full
transpose_table.sh $tmpDir/t_bvec_full > ${NIFTIout}.bvec



rm -fR $tmpDir