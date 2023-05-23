#!/bin/bash
source `which my_do_cmd`
# Help function
function help() {
		echo "
		Compute a T2 map in nifti format.
		

		use:
		`basename $0` raw_t2_images_4D.nii.gz t2map.nii.gz echoes.txt threshold
    Threshold is a value below which we consider noise.

		"
		exit 1
}



# ------------------------
# Parsing the command line
# ------------------------
if [ "$#" -lt 3 ]; then
		echo "[ERROR] - Not enough arguments"
		help
fi
raw=$1
t2map=$2
echoes=$3
mask=$4


vMask=`fslstats $mask -V | awk '{print $1}'`
if [ $vMask -eq 0 ]
then
  echo "  Mask is empty. Creating an emtpy t2 map."
  fslmaths $mask -mul 0 $t2map -odt float
  exit 2
fi


MatlabCMD=/home/inb/lconcha/fmrilab_software/myMatlab/bin/matlab
$MatlabCMD -nodisplay <<EOF
  [hdr_echoes,raw4D] = niak_read_nifti('$raw');
  echoes    = load( '$echoes' );
  echoes    = echoes ./ 1000; % echoes are in ms
  [hdr_mask,mask]= niak_read_nifti('$mask');
  t2map     = t2relaxometry( raw4D, echoes', mask );
  t2map     = t2map .* 1000; %back into ms
  t2map(~(isnumeric(t2map))) = 0;
  if ndims(t2map) == 2
    t2map(:,:,1) = t2map;
  end
  size(t2map)
  hdr_t2map = hdr_mask;
  hdr_t2map.info.precision = 'float32';
  hdr_t2map.info.dimensions(4) = 1
  hdr_t2map.file_name      = '$t2map';
  hdr_t2map.info
  niak_write_nifti(hdr_t2map,single(t2map));
EOF



