#/bin/bash
source `which my_do_cmd`


nii_dti=$1
nii_mask=$2
nii_dti_cropped=$3
nboundary_voxels=$4




rs=`random_string`
tmpDir=/tmp/${rs}
mkdir -p $tmpDir

      dti_orient=`fslorient -getorient $nii_dti`
      mask_orient=`fslorient -getorient $nii_mask`
      if [[ "$dti_orient" == "RADIOLOGICAL" ]]
      then
	cp $nii_dti ${tmpDir}/nii_dti.nii.gz
	nii_dti=${tmpDir}/nii_dti.nii.gz
	my_do_cmd fslorient -forceneurological $nii_dti
      fi
      if [[ "$mask_orient" == "RADIOLOGICAL" ]]
      then
	cp $nii_mask ${tmpDir}/nii_mask.nii.gz
	nii_mask=${tmpDir}/nii_mask.nii.gz
	my_do_cmd fslorient -forceneurological $nii_mask
      fi

mnc_dti=${tmpDir}/mnc_dti.mnc
my_do_cmd gunzip -v $nii_dti
my_do_cmd nii2mnc ${nii_dti%.gz} $mnc_dti
my_do_cmd gzip -v ${nii_dti%.gz}


mnc_mask=${tmpDir}/mnc_mask.mnc
my_do_cmd gunzip -v $nii_mask
my_do_cmd nii2mnc ${nii_mask%.gz} $mnc_mask
my_do_cmd gzip -v ${nii_mask%.gz}
my_do_cmd autocrop_volume $mnc_mask ${mnc_mask%.mnc}_2.mnc 0 $nboundary_voxels
mnc_mask=${mnc_mask%.mnc}_2.mnc


fslinfo nii_dti  | grep ^dim4 | awk '{print $2}'
mnc_dti_cropped=${tmpDir}/mnc_dti_cropped.mnc

mnc_basename=${tmpDir}/mnc_basename

my_do_cmd mincsplit $mnc_dti $mnc_basename


mnc_cropped_base=${tmpDir}/cropped
for f in `ls ${mnc_basename}*`
do
  num=`echo $f | awk -Fbasename '{print $NF}' | awk -F. '{print $1}'`
  num=`printf "%02d" $num`
  my_do_cmd autocrop -from $mnc_mask $f ${mnc_cropped_base}_fixed_${num}.mnc
done


echo "Will join these files in this order:"
ls ${mnc_cropped_base}_fixed_
fnames=`ls ${mnc_cropped_base}_fixed_*.mnc`

my_do_cmd mincjoin $fnames $mnc_dti_cropped




my_do_cmd mnc2nii -nii -short $mnc_dti_cropped $nii_dti_cropped
my_do_cmd gzip -v $nii_dti_cropped

echo "removing directory $tmpDir"
rm -fR $tmpDir
