#!/bin/bash
source `which my_do_cmd`
FSLOUTPUTTYPE=NIFTI


##########################
subject=$1
surf=$2
OUT_DIR=${SUBJECTS_DIR}/${subject}/dti/$3
##########################


### Defaults #############
keep_tmp=0
fakeflag=""
radius=1
number=500
length=30
MATLABCOMMAND=`which matlab`
tmpDir=/tmp/seedSurf_`random_string`
keep_p_clouds=0
keep_tracks=0
weighted_average=0
conn_threshold=0.05
surf_ico_order=5
doSampling=1
onlyCheckInputs=0
aparc_surface_mask=0
surface_mask=""
vertex_mask_threshold=0
CSD_lmax=6
force_octave=0
dti_metrics="fa adc l1 l2 l3"
clobber=0
force_multi_threading=0
sendMail=0
email_password=""
doNotTrack=0
s_tout=120
##########################


all_aparc_regions="'unknown','bankssts','caudalanteriorcingulate','caudalmiddlefrontal','corpuscallosum','cuneus','entorhinal','fusiform','inferiorparietal','inferiortemporal','isthmuscingulate','lateraloccipital','lateralorbitofrontal','lingual','medialorbitofrontal','middletemporal','parahippocampal','paracentral','parsopercularis','parsorbitalis','parstriangularis','pericalcarine','postcentral','posteriorcingulate','precentral','precuneus','rostralanteriorcingulate','rostralmiddlefrontal','superiorfrontal','superiorparietal','superiortemporal','supramarginal','frontalpole','temporalpole','transversetemporal','insula'"

print_help()
{
echo "
`basename $0` <subjid> <?h.white> <OUT_DIR> [-Options]

?h.white is relative to the subject's surf directory. Do not specify it's full path.
OUT_DIR will be created within \${SUBJECTS_DIR}/\${SUBJECT}/dti

 Options:

-length <int>      Max length of tracts in mm. Default = $length.
-number <int>      Number of seeds per vertex. Default = $number.
-radius <float>    Radius of the seed sphere.  Default = $radius.
-matlab <fullPath> FullPath to the matlab binary Default: $MATLABCOMMAND.
-tmpDir <fullPath> Full path to a (writable) address used for storing tmp files.
-fake              Do a dry run.
-keep_tmp          Do not remove temporary files. 
-keep_p_clouds     Keep each p cloud (takes up lots of space and is a little slower).
-keep_tracks       Keep each .tck file (loooots of space!)
-weighted_average  Get the mean values per vertex,
                   but weighted by probability of connectivity to vertex.
-conn_threshold <float> Minimum number of tracks per voxel to be considered connected to the vertex.
                        This is expressed as the ratio between the number of tracks that cross
                        trhough the voxels over the number of seeds (i.e., ranges from 0 to 1).
-surf_ico_order <int>   The trgicoorder that mri_surf2surf takes as argument. Default is $surf_ico_order.
                        The larger the number, the more vertices the surface has. Try to keep it between
                        5 and 6 (around 10K and 40K vertices, respectively).
-doNotSample       Skip the sampling bit. Useful if you are keeping the p clouds.
-onlyCheckInputs   Only check that the inputs are all there, but do not execute processing.
-aparc_surface_mask <\"list of structure names separated by commas and between single quotes\"> Use aparc to make a mask. 
                    For example \"'superiorfrontal','inferiortemporal'\"
                    See the file ${FREESURFER_HOME}/FreeSurferColorLUT.txt to get the appropriate names.
-all_aparc_regions  Will do all the regions identified in aparc.annot. Basically the entire cortex.
                    Useful for whole-brain analysis as it skips seeding the callosum and the ventricles.
-surface_mask <file.txt>  A file with equal number of vertices as the \$surf_ico_order will produce (NOT FINISHED YET, DO NOT USE)
-vertex_mask_threshold <float>
-CSD_lmax <int>    It will look for a file called \${SUBJECTS_DIR}/\${SUBJECT}/dti_CSD\${CSD_lmax}.nii.gz
                   Default is $CSD_lmax .
-force_octave      Do not use Matlab at all.
-clobber           Overwrite previous result.
-force_multi_threading  Force the use of whatever threads are specified in ~/.mrtrix.conf
                        The usual approach is to set the number of threads to one, since the bottleneck of this script is not 
                        improved by multi_threading. Instead, use the cluster to send several cases at once.
-sendMail <email>       Send an email when done.
-email_password <string> Necessary for -sendMail
-doNotTrack             Skip the long tracking per vertex loop. Only useful for debugging.
-seed_timeout <seconds> Skip seeding a vertex if streamtrack has not finished in a given time.
                        Default is $s_tout seconds.

Luis Concha
INB
2012
"

}


started=`date`
######## Display welcome message
echo "Starting processing of `basename $0`"
echo "  Command was `basename $0` $@"
echo "  Started at `date`"
echo "  User: `whoami`"
echo "  Node: `uname -n`"
echo "  PID:   $$" 
echo ""



######### Check if help is needed
if [ $# -lt 3 ] 
then
  echo "  ERROR: Need more arguments..."
  print_help
  exit 1
fi




######### Parse the arguments and look for options
declare -i i
i=1
for arg in "$@"
do
  case "$arg" in
  -h|-help) 
    print_help
    exit 1
  ;;
  -fake)
    fakeflag="-fake"
  ;;
  -keep_tmp)
    keep_tmp=1
  ;;
  -length)
    nextarg=`expr $i + 1`
    eval length=\${${nextarg}}
  ;;
  -number)
    nextarg=`expr $i + 1`
    eval number=\${${nextarg}}
  ;;
  -radius)
    nextarg=`expr $i + 1`
    eval radius=\${${nextarg}}
  ;;
  -matlab)
    nextarg=`expr $i + 1`
    eval MATLABCOMMAND=\${${nextarg}}
  ;;
  -tmpDir)
    nextarg=`expr $i + 1`
    eval tmpDir=\${${nextarg}}
  ;;
  -keep_p_clouds)
    keep_p_clouds=1
  ;;
  -keep_tracks)
    keep_tracks=1
  ;;
  -weighted_average)
    weighted_average=1
  ;;
  -conn_threshold)
    nextarg=`expr $i + 1`
    eval conn_threshold=\${${nextarg}}
  ;;
  -surf_ico_order)
    nextarg=`expr $i + 1`
    eval surf_ico_order=\${${nextarg}}
  ;;
  -doNotSample)
    doSampling=0
  ;;
  -onlyCheckInputs)
    onlyCheckInputs=1
  ;;
  -aparc_surface_mask)
    aparc_surface_mask=1
    nextarg=`expr $i + 1`
    eval aparc_ROIs=\${${nextarg}}
  ;;
  -all_aparc_regions)
    aparc_surface_mask=1
    aparc_ROIs=$all_aparc_regions
  ;;
  -surface_mask)
    nextarg=`expr $i + 1`
    eval surface_mask=\${${nextarg}}
  ;;
  -vertex_mask_threshold)
    nextarg=`expr $i + 1`
    eval vertex_mask_threshold=\${${nextarg}}
  ;;
  -CSD_lmax)
    nextarg=`expr $i + 1`
    eval CSD_lmax=\${${nextarg}}
  ;;
  -force_octave)
    force_octave=1
  ;;
  -clobber)
    clobber=1
  ;;
  -force_multi_threading)
    force_multi_threading=1
  ;;
  -sendMail)
    nextarg=`expr $i + 1`
    eval email=\${${nextarg}}
    sendMail=1
  ;;
  -email_password)
    nextarg=`expr $i + 1`
    eval email_password=\${${nextarg}}
    sendMail=1
  -doNotTrack)
    doNotTrack=1
  ;;
  -seed_timeout)
    nextarg=`expr $i + 1`
    eval s_tout=\${${nextarg}}
  ;;
  esac
  i=$[$i+1]
done


##### Check that mrtrix.conf is OK
if [ ! -f ~/.mrtrix.conf ]
then
  echo "mrtrix configuration file does not exist. Creating one (~/.mrtrix.conf)"
  echo "NumberOfThreads: 1" > ~/.mrtrix.conf
fi
nThreads=`grep NumberOfThreads ~/.mrtrix.conf | awk '{print $2}'`
if [ $nThreads -gt 1 ]
then
  if [ $force_multi_threading -eq 0 ]
  then
      echo "Please modify NumberOfThreads to 1 in ~/.mrtrix.conf and try again. Bye."
      exit 2
  fi
fi





##### Check for files that we will need. Abort if not found.
filesNeeded="${SUBJECTS_DIR}/${subject}/dti/dti_CSD${CSD_lmax}.nii.gz \
            ${SUBJECTS_DIR}/${subject}/surf/$surf \
	    ${SUBJECTS_DIR}/$subject/dti/dti_fa.nii.gz \
	    ${SUBJECTS_DIR}/$subject/dti/ants_t1_to_faAffine.txt \
	    ${SUBJECTS_DIR}/$subject/dti/ants_t1_to_faInverseWarpzvec.nii.gz \
	    ${SUBJECTS_DIR}/$subject/dti/ants_t1_to_faWarpzvec.nii.gz \
	    ${SUBJECTS_DIR}/$subject/dti/ants_t1_to_faAffine.txt \
	    ${SUBJECTS_DIR}/${subject}/dti/dti_mask.nii.gz"
OK=1
for f in $filesNeeded
do
  if [ -f $f ]
  then
    echo "OK, found file: $f"
  else
    echo "CRITICAL ERROR, file does not exist: $f"
    OK=0
  fi
done

if [ $doSampling -eq 1 ]
then
  for thismetric in $dti_metrics
  do
    f=${SUBJECTS_DIR}/${subject}/dti/dti_${thismetric}.nii.gz
    if [ -f $f ]
    then
      echo "OK, found file: $f"
    else
      echo "CRITICAL ERROR, file does not exist: $f"
      OK=0
    fi
  done
fi

### Prepare the output directory
if [ ! -d $OUT_DIR ]
then
  my_do_cmd mkdir -p $OUT_DIR
fi
if [ ! -d $OUT_DIR ]
then
  OK=0
  echo "Cannot create output directory $OUT_DIR"
fi



if [ $OK -eq 0 ]
then
  echo "
  Cannot continue.
  Please see if you have run the freesurfer pipeline, and the following commands:
     inb_freesurfer_dti_registration.sh
     inb_freesurfer_mrtrix_proc.sh

  Bye.
  "
  exit 2
fi

if [ $onlyCheckInputs -eq 1 ]
then
  echo "Finished checking inputs".
  if [ $OK -eq 0 ]
  then
      echo "There are errors with subject $subject"
      exit 2
  else
      echo "The future is bright for subject $subject"
      exit 2
  fi
fi





######### Create a temporary directory
mkdir -p $tmpDir
tmpbase=${tmpDir}/tmp_
outbase=${tmpDir}/subasta


######### Save some files to aid knowing what I did
# It also contains the PID of the command, so we can cancel it if needed. (use kill PID)
cmdFile=${outbase}_command.txt
echo "cmdFile is $cmdFile"
date > $cmdFile
uname -a  >> $cmdFile
whoami >> $cmdFile
echo "PWD  : $PWD" >> $cmdFile
echo "PID  : $$" >> $cmdFile
echo "PPID : $PPID" >> $cmdFile
echo "Actual command invoked:" >> $cmdFile
echo "  $0 $@" >> $cmdFile
echo "" >> $cmdFile
echo "#### ENV follows####" >> $cmdFile
env >> $cmdFile







# Copy some images so that we are not reading the originals all the time.
# this is only useful if tmpdir is a local directory, and not through NFS.
for v in ${dti_metrics}
do
  my_do_cmd $fakeflag fslmaths \
   ${SUBJECTS_DIR}/$subject/dti/dti_${v} \
   -mul 1 \
   ${tmpbase}${v}
done



########### Resample the surface so that it has less vertices
r_surf=${tmpbase}_r_$surf
side=${surf%.*}
surfType=${surf#*.}
my_do_cmd $fakeflag mri_surf2surf \
  --srcsubject $subject \
  --sval-xyz $surfType \
  --tval-xyz \
  --noreshape \
  --tval $r_surf  \
  --hemi $side \
  --trgicoorder $surf_ico_order \
  --trgsubject ico
# keep a version of this file for future display purposes
cp -v $r_surf ${outbase}_r_$surf



#### APARC MASK
if [ $aparc_surface_mask -eq 1 ]
then
  mask_vertices_annot=${tmpDir}/mask_vertices.annot
  mask_vertices_txt=${tmpDir}/mask_vertices.txt
  my_do_cmd $fakeflag mri_surf2surf \
    --srcsubject $subject \
    --sval-xyz $surfType  \
    --tval $mask_vertices_annot \
    --hemi $side \
    --trgicoorder $surf_ico_order \
    --trgsubject ico \
    --sval-annot aparc.annot
  echo "OCTAVE: octave --eval mask = inb_freesurfer_annot_to_vertex_mask('$mask_vertices_annot','$mask_vertices_txt',{${aparc_ROIs}});"
  octave --eval "mask = inb_freesurfer_annot_to_vertex_mask('$mask_vertices_annot','$mask_vertices_txt',{${aparc_ROIs}});"
  nMaskOnes=`grep 1 $mask_vertices_txt | wc -l`
fi





######### Warp the surface from T1 to dti space (warp field must exist)

 # first we must make the surface a fake track, so we can use normalise_tracks
t1=${tmpbase}brain.nii
my_do_cmd $fakeflag mri_convert \
  ${SUBJECTS_DIR}/$subject/mri/brain.mgz \
  $t1

if [ -z $fakeflag ]
then
  if [ ! -z `which $MATLABCOMMAND` -a $force_octave -eq 0 ]
  then
    echo "MATLAB: freesurfer_surf_to_fakeTrack('$r_surf','${tmpbase}_surf.tck','$t1'); "
    $MATLABCOMMAND -nodisplay <<EOF
    freesurfer_surf_to_fakeTrack('$r_surf','${tmpbase}_surf.tck','$t1');
EOF
  else
    if [ -z `which octave` ]
    then
      echo "Did not find either matlab or octave. Quitting."
      exit 2
    else
      echo "OCTAVE: freesurfer_surf_to_fakeTrack('$r_surf','${tmpbase}_surf.tck','$t1'); " 
      octave --eval "freesurfer_surf_to_fakeTrack('$r_surf','${tmpbase}_surf.tck','$t1');"
    fi
  fi

fi


 # We prepare the deformation field to be applied to the fake track (surf)
my_do_cmd $fakeflag gen_unit_warp \
  ${SUBJECTS_DIR}/$subject/dti/dti_fa.nii.gz \
  ${tmpbase}nowarp-[].nii
for n in 0 1 2
do
  my_do_cmd $fakeflag WarpImageMultiTransform 3 \
    ${tmpbase}nowarp-${n}.nii \
    ${tmpbase}w_${n}.nii \
    -i ${SUBJECTS_DIR}/$subject/dti/ants_t1_to_faAffine.txt  \
    ${SUBJECTS_DIR}/$subject/dti/ants_t1_to_faInverseWarp.nii.gz \
    -R ${tmpbase}brain.nii	
    my_do_cmd $fakeflag fslreorient2std ${tmpbase}nowarp-${n}.nii ${tmpbase}nowarp-${n}_std.nii
done



 # Now let's warp the filled WM from freesurfer space to T1.
 # It will be used to constrain the tractography and avoid it from going into the cortex. 
my_do_cmd $fakeflag mri_convert \
  ${SUBJECTS_DIR}/$subject/mri/filled.mgz \
  ${tmpbase}_filled.nii
my_do_cmd $fakeflag WarpImageMultiTransform 3 \
  ${tmpbase}_filled.nii \
  ${tmpbase}_filled_warped.nii \
  ${SUBJECTS_DIR}/$subject/dti/ants_t1_to_faWarp.nii.gz \
  ${SUBJECTS_DIR}/$subject/dti/ants_t1_to_faAffine.txt  \
  -R ${SUBJECTS_DIR}/$subject/dti/dti_fa.nii
my_do_cmd $fakeflag fslreorient2std ${tmpbase}_filled_warped.nii ${tmpbase}_filled_warped_rstd.nii



 # OK, finally, we warp the surface from freesurfer to dti space
surf_as_track=${outbase}_surf_in_dti.tck
my_do_cmd $fakeflag normalise_tracks \
  ${tmpbase}_surf.tck \
  ${tmpbase}w_[].nii \
  $surf_as_track

 # And now we turn it to ASCII format so I can read it.
surf_ascii=${tmpbase}_surf_ascii
my_do_cmd $fakeflag track_info \
  -ascii $surf_ascii $surf_as_track

 # Just to be kind and ease debugging, make an ascii surface with the warped coordinates that can be loaded into freeview
  my_do_cmd $fakeflag inb_freesurfer_modify_surface_coords.sh \
    $r_surf ${surf_ascii}-000000.txt ${outbase}_${surf/./_}_warped_to_dti.asc
  
 # We check that all the vertices are within the mask.
 # I do this because sometimes the normalise_tracks gives some vertices in odd places (inf)
 # While the right thing to do is to check why it is doing that, there are so few vertices (around 10) 
 # that I prefer to simply ignore those vertices for now.

if [ -z $fakeflag ]
then
  #dti_mask=${SUBJECTS_DIR}/${subject}/dti/dti_mask.nii.gz
  dti_mask=${tmpbase}_filled_warped_rstd.nii
  my_do_cmd $fakeflag fslmaths $dti_mask -bin -dilM -bin ${dti_mask%.nii}_dil.nii
  dti_mask=${dti_mask%.nii}_dil.nii
  echo "dti_mask is $dti_mask"
  mask_vertex_values=${outbase}_mask_${surf/./_}_vertex_values.txt
  if [ ! -z `which $MATLABCOMMAND` -a $force_octave -eq 0 ]
  then
    echo "MATLAB: image_values = inb_sampleVolume('$dti_mask','${surf_ascii}-000000.txt','$mask_vertex_values'); "
    $MATLABCOMMAND -nodisplay <<EOF
    image_values = inb_sampleVolume('$dti_mask','${surf_ascii}-000000.txt','$mask_vertex_values');
EOF
  else
    if [ -z `which octave` ]
    then
      echo "Did not find either matlab or octave. Quitting."
      exit 2
    else
      echo "OCTAVE: image_values = inb_sampleVolume('$dti_mask','${surf_ascii}-000000.txt','$mask_vertex_values'); " 
      octave --eval "image_values = inb_sampleVolume('$dti_mask','${surf_ascii}-000000.txt','$mask_vertex_values');"
    fi
  fi

fi

  

##### And now we seed from the surface!!!! 
if [ $doNotTrack -eq 0 ]
then
  nVertices=`wc -l ${surf_ascii}-000000.txt | awk '{print $1}'`
  CSD=${SUBJECTS_DIR}/${subject}/dti/dti_CSD${CSD_lmax}.nii.gz
  tmpCSD=${tmpbase}_CSD.mif
  echo "  Converting CSD file to a tmp mif file."
  my_do_cmd mrconvert $CSD $tmpCSD
  CSD=$tmpCSD
  mask=$dti_mask
  vertex=0
  tmpTrack=${tmpbase}_TMPTRACK.tck
  track_log=${outbase}_tracking.errors
  list_of_p_files=${tmpbase}_list_of_p_files.txt



  if [ ! -z $surface_mask ]
  then
    nLines=`wc -l $surface_mask | awk '{print $1}'`
    if [ $nLines -ne $nVertices ]
    then
      echo "ERROR: Incompatible number of vertices between the surface and surface mask"
      echo "                                                     ^--($nVertices)    ^--($nLines)"
    else
      echo "OK:  Surface and surface mask both have $nVertices vertices"
      echo "INFO: The surface mask threshold is $vertex_mask_threshold"
    fi
  fi



errorSample(){
doSampling=$1
dti_metrics=$2
vertex=$3
vx=$4
vy=$5
vz=$6
outbase=$7
if [ $doSampling -eq 1 ]
then
  # Print some junk to that specific vertex
  for v in ${dti_metrics}
  do
    printf "%4.6d %2.5f %2.5f %2.5f %s\n" $vertex $vx $vy $vz NaN | tee -a ${outbase}_${v}.asc
  done
  echo "NaN NaN NaN NaN NaN" | tee -a ${outbase}_valuesPerVertex.txt
fi
}




  ###### BEGIN HUGE LOOP
  seedsDone=0
  cat ${surf_ascii}-000000.txt | while read line
  do

    
    pcentDone=`echo "$vertex *100 / $nVertices" | bc -l`
    actual_pcentDone=`echo "$seedsDone *100 / $nMaskOnes" | bc -l`
    vx=`echo $line | awk '{print $1}'`
    vy=`echo $line | awk '{print $2}'`
    vz=`echo $line | awk '{print $3}'`
    seed="$vx,$vy,$vz,$radius"
    echo " ## Working on vertex $vertex / $nVertices (${pcentDone:0:4}%) ($seedsDone / $nMaskOnes actual seeds; ${actual_pcentDone:0:4}%) [seed: $seed]"
    

    if [ $aparc_surface_mask -eq 1 ]
    then
      mask_line_num=$(($vertex+1))
      thisVmaskValue=`sed -n "$mask_line_num"'p' $mask_vertices_txt` 
      #echo "thisVmaskValue is $thisVmaskValue"
      if [ $thisVmaskValue -eq 0 ] 
      then
	  echo "     (skipping)"
          errorSample $doSampling "$dti_metrics" $vertex $vx $vy $vz $outbase
	  vertex=$(($vertex+1))
	  continue
      fi
    fi
  
    if [ ! -z $surface_mask ]
    then
      mask_line_num=$(($vertex+1))
      thisVmaskValue=`sed -n "$mask_line_num"'p' $surface_mask` 
      # bash cannot do floating point comparisons, so here goes this stupidity
      isLessThan=`echo "$thisVmaskValue < $vertex_mask_threshold" | bc`
      if [ $isLessThan -eq 1 ] 
      then
	  echo "     (skipping because thisVmaskValue is $thisVmaskValue, which is less than $vertex_mask_threshold)"
	  errorSample $doSampling "$dti_metrics" $vertex $vx $vy $vz $outbase $v
	  vertex=$(($vertex+1))
	  continue
      fi
    fi


    
    tracks_p_from_surface=${outbase}_tracks_from_surface_`zeropad ${vertex} 7`.nii
    if [ -f $tracks_p_from_surface ]
    then
      echo "  Vertex already computed"
      echo "FATAL ERROR: Something wrong is going on here!"
      exit 2
    fi
    
    v_index=$(($vertex + 1))
    this_mask_value_float=`sed -n "${v_index}p" $mask_vertex_values`
    this_mask_value=`awk -v val=$this_mask_value_float 'BEGIN { printf "%.0f\n", val }'`
    if [ $this_mask_value -eq 0 ]
    then
	echo "  ERROR: Vertex $vertex is bad ($vx,$vy,$vz), skipping it."
	errorSample $doSampling "$dti_metrics" $vertex $vx $vy $vz $outbase $v
	vertex=$(($vertex + 1))
	continue
    fi


    #my_do_cmd -log $track_log $fakeflag timeout $s_tout streamtrack \
    if [ -z $fakeflag ]
    then
      timeout $s_tout streamtrack \
	-quiet \
	-seed $seed \
	-unidirectional \
	-mask $mask \
	-number $number \
	-initcutoff 0.0001 \
	-cutoff 0.0001 \
	-length $length \
	-trials $(($number * 10)) \
	SD_PROB $CSD \
	$tmpTrack > $track_log
      lastExitStatus=$?
      if [ $lastExitStatus -gt 120 ]
      then
	echo "There was an error tracking vertex $vertex, timed out at $s_tout seconds"
	errorSample $doSampling "$dti_metrics" $vertex $vx $vy $vz $outbase $v
	vertex=$(($vertex + 1))
	continue
      fi
    fi
    
    
    seedsDone=$(($seedsDone + 1))
    if [ $keep_tracks -eq 1 ]
    then
      cp $tmpTrack ${tracks_p_from_surface%.nii}.tck
    fi
    

    if [ -f ${tmpTrack%.tck}.nii ]; then rm ${tmpTrack%.tck}.nii;fi
      my_do_cmd $fakeflag tracks2prob \
      -fraction \
      -datatype float32 \
      -template $mask \
      $tmpTrack \
      ${tmpTrack%.tck}.nii | grep error | tee -a $track_log


    if [ $keep_p_clouds -eq 1 ]
    then
      fslmaths ${tmpTrack%.tck}.nii -mul 100 $tracks_p_from_surface -odt char
    else
      tracks_p_from_surface=${tmpTrack%.tck}.nii
    fi
    


    # Get the relevant data!
    if [ $doSampling -eq 1 ]
    then
      vertexValues=""
      if [ $weighted_average -eq 0 ]
      then
	#echo "  Create a connectivity mask"
	fslmaths \
	    $tracks_p_from_surface \
	    -thr $conn_threshold \
	    -bin \
	    ${tmpbase}_v_conn_mask.nii

      else
	cp -f $tracks_p_from_surface ${tmpbase}_v_conn_mask.nii
      fi
      for v in ${dti_metrics}
      do
	fslmaths \
	  ${tmpbase}${v} \
	  -mul ${tmpbase}_v_conn_mask.nii \
	  ${tmpbase}_${v}_masked.nii
	thisValue=`fslstats ${tmpbase}_${v}_masked.nii -M`
	#echo "  $v : $thisValue"
	printf "%4.6d %2.5f %2.5f %2.5f %2.5f\n" $vertex $vx $vy $vz $thisValue >> ${outbase}_${v}.asc
	vertexValues="${vertexValues} $thisValue"
      done

      echo $vertexValues | tee -a ${outbase}_valuesPerVertex.txt
    fi


    
    if [ $keep_p_clouds -eq 1 ]
    then
      gzip $tracks_p_from_surface
      echo ${tracks_p_from_surface}.gz >> $list_of_p_files  
    else
      rm $tracks_p_from_surface
    fi
    
    vertex=$(($vertex + 1))
  done
  ## End huge loop
fi


####  SAVE ALL OUTPUT!!!! ########
cp -v ${outbase}* ${OUT_DIR}/
##################################

#### Finally, cleanup.
if [ $keep_tmp -eq 0 ]
then
  rm -fR ${tmpDir}
else
  echo "Temp files not removed, they are still in the directory:"
  echo "  $tmpDir"
fi


if [ $sendMail -eq 1 ]
then
finished=`date`
echo Sending mail to $email
sendemail \
  -f inb.fmrilab@gmail.com \
  -t $email \
  -u "[seed surface] Finished $subject $surf" \
  -m "Started at  : $started
      Finished at : $finished" \
  -s smtp.gmail.com:587 \
  -xu inb.fmrilab \
  -xp $email_password
fi


