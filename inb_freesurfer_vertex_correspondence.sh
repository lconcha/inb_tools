#!/bin/bash
source `which my_do_cmd`

fakeflag=""

subject=$1
dataName=$2
#surf_type=$3



for hemi in lh
do
  #surf_mgh=/tmp/freesurfer_`random_string`_${hemi}_fsaverage.mgh
  surf_mgh=${SUBJECTS_DIR}/${subject}/surf/${hemi}_`basename ${dataName%.asc}`_fsaverage.mgh
  data_link=${SUBJECTS_DIR}/${subject}/surf/${hemi}.data_link.asc

  my_do_cmd $fakeflag ln -s $dataName $data_link

  # First we resample the data to fsaverage
  my_do_cmd $fakeflag mris_preproc \
    --s $subject \
    --hemi ${hemi} \
    --meas data_link.asc  \
    --target fsaverage \
    --out $surf_mgh

  # And now we project the data onto the different fsaverage surfaces.
  for t in white pial inflated sphere
  do
    my_do_cmd $fakeflag mris_convert \
      -c $surf_mgh \
      $FREESURFER_HOME/subjects/fsaverage/surf/${hemi}.${t} \
      ${SUBJECTS_DIR}/${subject}/surf/${hemi}_`basename ${dataName%.asc}`_fsaverage.${t}.asc
  done

  if [ -f $data_link ]
  then
  #echo keeping $data_link
   my_do_cmd $fakeflag rm $data_link
  fi
done