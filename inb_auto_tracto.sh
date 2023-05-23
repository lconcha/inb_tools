#!/bin/bash
source `which my_do_cmd`
fakeflag=""
export FSLOUTPUTTYPE=NIFTI



## Defaults ################################
autoPtx=/misc/mansfield/lconcha/autoPtx
filtering=0
seeding=0
nSeeds=500
CSD=""
tckIN=""
# t1==""
outbase=""
mask=""
fa=""
mat=""
doNull=0
keep_tmp=0
tmpDir=`pwd`/tmpDir
## End Defaults ################################




help() {
echo "
`basename $0`


Perform automatic virtual dissection of a full-brain tractogram.
This can be performed in two ways:
a) Provide a pre-computed tck file and it will be dissected.
b) Provide the necessary CSD files to compute the tractogram for you.


Since this script uses fsl tools (FLIRT, in particular), please provide volumes in .nii format.

To use option a), provide a command like this one:
`basename $0` -tck mytractogram.tck -outbase my_out -fa fa.nii -mask mask.nii 
This is the preferred way of using this script. 
And even better if your tck file has been SIFTED.

To use option b), provide a command like this one:

`basename $0` -CSD csd.nii -outbase my_out -mask mask.nii -nSeeds 1000 




This is an adaptation of auto_ptx to work with mrtrix.
https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/AutoPtx

Options:
  -h|-help
  -CSD <file>       : CSD file from dwi2fod. 
  -tck <file>       : .tck file (SIFTED, preferraly.)
  -outbase <string> : base name for all your outputs.
  -mask <file>      : Binary mask in subject dwi space.
  -fa <file>        : FA map in subject dwi space. Used for registration to template.
  -mat <file>       : If you would like to register your dwi space to standard space.
  -nSeeds <int>     : Number of seeds per region to track (incompatible with -tck). Default is $nSeeds.
  -doNull           : Do null tractogram (for statistical purposes - unfinished)
  -autoPtx <path>   : Fill path to auto_ptx protocol directory.
                      Default is $autoPtx.
  -keep_tmp         : Do not delete temp directory.
  -tmpDir <path>



LU15 (0N(H4
May, 2016
Rev Oct 2017
INB, UNAM
lconcha@unam.mx

"
}



if [ "$#" -lt 2 ]; then
  echo "[ERROR] - Not enough arguments"
  help
  exit 2
fi



for arg in "$@"
do
  case "$arg" in
  -h|-help) 
    help
    exit 1
  ;;
  -CSD)
    CSD=$2
    echo "    CSD is $CSD"
    shift;shift
    seeding=1
  ;;
  -tck)
    tckIN=$2
    shift;shift
    echo "    tckIN is $tckIN"
    filtering=1
   ;;
  -outbase)
    outbase=$2
    shift;shift
    echo "    outbase is $outbase" 
  ;;
  -mask)
    mask=$2
    shift;shift
    echo "    mask is $mask"
    ;;
  -fa)
    fa=$2
    shift;shift 
    echo "    fa is $fa" 
    ;;
  -mat)
    mat=$2
    shift;shift
    echo "    mat is $mat" 
  ;;
  -nSeeds)
    nSeeds=$2
    shift;shift
    echo "    nSeeds is $nSeeds"
  ;;
  -doNull)
    doNull=1
    shift
  ;;
  -autoPtx)
    autoPtx=$2
    shift;shift
    echo "    autoPtx is $autoPtx"
   ;;
  -keep_tmp)
    keep_tmp=1
   ;;
  -tmpDir)
    tmpDir=$2
    shift;shift
    echo "    tmpDir is $tmpDir"
   ;;

  
  esac
done


## Argument checks
if [ -z "$CSD" -a -z "$tckIN" ]
then
  echo "ERROR: You must supply either -CSD or -tck"
  help
  exit 2
fi

if [ $seeding -eq 0 -a $filtering -eq 0 ]
then
  echo "ERROR: You must supply either -seeding or -filtering"
  help
  exit 2
fi

if [ $filtering -eq 1 ]
then
  if [ -z "$tckIN" ]
  then
    echo "ERROR: You must use -tck if you are using -filtering"
    help
    exit 2
  fi
  if [ -z $fa ]
  then
    echo "ERROR: You must use -fa if you are using -filtering"
    help
    exit 2
  fi
fi

if [ $seeding -eq 1 ]
then
  if [ -z "$CSD" ]
  then
    echo "ERROR: You must -CSD if you are using -seeding"
    help
    exit 2
  fi
fi

if [ -z "$fa" ]
then 
  if [ ! -z "$mat" ]
  then
    echo "Please supply either -fa or -mat"
    help
    exit 2
  fi
fi

if [ -z $mask ];    then echo "Please supply -mask"   ;help;exit 2;fi
if [ -z $outbase ]; then echo "Please supply -outbase";help;exit 2;fi
if [ -z $fa ];      then echo "Please supply -fa"     ;help;exit 2;fi
##### End argument checks


# find the structures and the atlas
structures=`ls -1 $autoPtx/protocols`
atlas=${FSLDIR}/data/standard/FMRIB58_FA_1mm.nii.gz


# Create temp directory
mkdir $tmpDir



## Registration of atlas to subject DWI space
echo " [INFO] Checking if We have a transformation between atlas and fa."
if [ ! -z $mat ]
then
  echo "A transformation matrix was supplied: $mat"
  mat_atlas2fa=$mat
else
  mat_atlas2fa=${outbase}_atlas2fa.mat
fi
if [ ! -f $mat_atlas2fa ]
then
  echo " [INFO] No transformation was supplied. Calculating: $mat_atlas2fa"
  my_do_cmd $fakeflag flirt -in $atlas -ref $fa -omat $mat_atlas2fa -out ${outbase}_atlas2fa.nii -dof 12 -v
else
  echo "  Transformation exists: $mat_atlas2fa"
fi





track(){
  st=$1
  CSD=$2
  autoPtx=$3
  outbase=$4
  mask=$5
  mat=$6
  tmpDir=$7
  fa=$8
  nSeeds=$9
  doNull=${10}
  seed=${autoPtx}/protocols/${st}/seed.nii
  target=${autoPtx}/protocols/${st}/target.nii
  exclude=${autoPtx}/protocols/${st}/exclude.nii
  stop=${autoPtx}/protocols/${st}/stop.nii
  if [ -f ${autoPtx}/protocols/${st}/invert ]
  then
    invert=1
  else
    invert=0
  fi
  # Move ROIs from standard to subject space
  my_do_cmd $fakeflag flirt -ref $fa -in $seed    -applyxfm -init $mat -out ${tmpDir}/seed.nii
  my_do_cmd $fakeflag flirt -ref $fa -in $target  -applyxfm -init $mat -out ${tmpDir}/target.nii
  my_do_cmd $fakeflag flirt -ref $fa -in $exclude -applyxfm -init $mat -out ${tmpDir}/exclude.nii
  my_do_cmd $fakeflag flirt -ref $fa -in $stop    -applyxfm -init $mat -out ${tmpDir}/stop.nii

  echo "  Tracking structure $st
            seed:    $seed
                     ${tmpDir}/seed.nii
            target:  $target
                     ${tmpDir}/target.nii
            exclude: $exclude
                     ${tmpDir}/exclude.nii
            stop:    $stop
                     ${tmpDir}/stop.nii
            invert:  $invert
            CSD:     $CSD"


  # Forward tracking (and the only one if not using -inverse)
  my_do_cmd $fakeflag tckgen $CSD ${outbase}_${st}.tck -force -algorithm iFOD2 \
            -seed_image ${tmpDir}/seed.nii \
            -include ${tmpDir}/target.nii \
            -exclude ${tmpDir}/exclude.nii \
            -mask $mask \
            -number $nSeeds

  # null distribution (forward, and only if not using -invert)
  if [ $doNull -eq 1 ]
  then
      my_do_cmd $fakeflag tckgen $CSD ${outbase}_${st}_null.tck -force -algorithm Nulldist \
            -seed_image ${tmpDir}/seed.nii \
            -include ${tmpDir}/target.nii \
            -exclude ${tmpDir}/exclude.nii \
            -mask $mask \
            -number $(($nSeeds * 20))
  fi


  
  # If using -invert then we seed again and, if requested, also for null dist.
  if [ $invert -eq 1 ]
  then
    echo "  Inverting seed and target ROIs"
    my_do_cmd $fakeflag tckgen $CSD ${outbase}_${st}_inv.tck -force -algorithm iFOD2 \
            -include ${tmpDir}/seed.nii \
            -seed_image ${tmpDir}/target.nii \
            -exclude ${tmpDir}/exclude.nii \
            -mask $mask \
            -number $nSeeds
    echo "  Merging forward and reverse seedings"
    mv -v  ${outbase}_${st}.tck ${outbase}_${st}_fwd.tck
    my_do_cmd $fakeflag  tckedit \
           ${outbase}_${st}_fwd.tck \
           ${outbase}_${st}_inv.tck \
           ${outbase}_${st}.tck

    if [ $doNull -eq 1 ]
    then
      echo "  Inverting seed and target ROIs"
      my_do_cmd $fakeflag tckgen $CSD ${outbase}_${st}_inv_null.tck -force -algorithm Nulldist \
	      -include ${tmpDir}/seed.nii \
	      -seed_image ${tmpDir}/target.nii \
	      -exclude ${tmpDir}/exclude.nii \
	      -mask $mask \
	      -number $(($nSeeds * 20))
      echo "  Merging forward and reverse seedings"
      mv -v  ${outbase}_${st}_null.tck ${outbase}_${st}_fwd_null.tck
      my_do_cmd $fakeflag  tckedit \
	    ${outbase}_${st}_fwd_null.tck \
	    ${outbase}_${st}_inv_null.tck \
	    ${outbase}_${st}_null.tck

    fi


  fi

  ## Tracto p poisson is only done if doing null distribution
  if [ $doNull -eq 1 ]
  then
      if [ $invert -eq 1 ]
      then 
          totalSeeds=$(($nSeeds * 2))
          seed_map=$tmpDir/seed_map.nii
          my_do_cmd $fakeflag mrcalc -force ${tmpDir}/seed.nii ${tmpDir}/target.nii -add $seed_map
      else 
          totalSeeds=$nSeeds
          cp ${tmpDir}/seed.nii $seed_map
      fi
      tdi_map=${tmpDir}/tdi_map.nii
      tdi_null_map=${tmpDir}/tdi_null_map.nii
      v_null_map=${tmpDir}/v_null_map.nii
      track_p=${outbase}_${st}_p.nii
      my_do_cmd $fakeflag tckmap -force ${outbase}_${st}.tck $tdi_map -contrast tdi -template $fa
      my_do_cmd $fakeflag tckmap -force ${outbase}_${st}_null.tck $tdi_null_map -contrast tdi -template $fa
      my_do_cmd $fakeflag mrcalc -force $tdi_null_map $totalSeeds -mul $(($totalSeeds * 20)) -div $v_null_map
      /home/inb/lconcha/fmrilab_software/tools/fmrilab_matlab.sh -nodisplay <<EOF
p = tracto_p_poisson('$seed_map','$tdi_map','$v_null_map',0.05,true,'$track_p');
EOF
      my_do_cmd $fakeflag mrcalc -force $track_p 0.05 -lt ${tmpDir}/track_p_mask.mif
      # next line truncates streamlines that exit the high-probability region estimated above.
      my_do_cmd $fakeflag tckedit -mask ${tmpDir}/track_p_mask.mif ${outbase}_${st}.tck ${outbase}_${st}_masked.tck
      my_do_cmd $fakeflag tckmap ${outbase}_${st}_masked.tck ${outbase}_${st}_masked.nii \
                -contrast tdi -template $fa
  fi

}


filter(){
  st=$1
  tckIN=$2
  autoPtx=$3
  outbase=$4
  mat=$5
  tmpDir=$6
  fa=$7
  seed=${autoPtx}/protocols/${st}/seed.nii
  target=${autoPtx}/protocols/${st}/target.nii
  exclude=${autoPtx}/protocols/${st}/exclude.nii
  stop=${autoPtx}/protocols/${st}/stop.nii
  nat_seed=${tmpDir}/${st}_nat_seed.nii
  nat_target=${tmpDir}/${st}_nat_target.nii
  nat_exclude=${tmpDir}/${st}_nat_exclude.nii
  nat_stop=${tmpDir}/${st}_nat_stop.nii
  summary=${outbase}_summary.txt

  if [ -f ${autoPtx}/protocols/${st}/invert ]
  then
    invert=1
  else
    invert=0
  fi
  my_do_cmd $fakeflag flirt -ref $fa -in $seed    -applyxfm -init $mat -out $nat_seed
  my_do_cmd $fakeflag flirt -ref $fa -in $target  -applyxfm -init $mat -out $nat_target
  my_do_cmd $fakeflag flirt -ref $fa -in $exclude -applyxfm -init $mat -out $nat_exclude
  my_do_cmd $fakeflag flirt -ref $fa -in $stop    -applyxfm -init $mat -out $nat_stop

  echo "  Filtering full tractogram to retreive structure $st
            seed:    $seed
                     $nat_seed
            target:  $target
                     $nat_target
            exclude: $exclude
                     $nat_exclude
            stop:    $stop
                     $nat_stop
            invert:  $invert
            CSD:     $CSD"

  my_do_cmd $fakeflag tckedit -force \
            $tckIN \
            ${outbase}_f_${st}.tck \
            -include $nat_seed \
            -include $nat_target \
            -exclude $nat_exclude
 nTcks=`tckinfo -count ${outbase}_f_${st}.tck | grep "actual count" | awk '{print $NF}'`  
 echo "$st $nTcks" >> $summary
}


structures=`ls -1 $autoPtx/protocols`
for st in $structures
do
  echo "Working on $st"
  if [ $seeding -eq 1 ]
  then
    track $st $CSD $autoPtx $outbase $mask $mat_atlas2fa $tmpDir $fa $nSeeds $doNull
    gzip -v ${outbase}*.nii
  fi

  if [ $filtering -eq 1 ]
  then
    filter $st $tckIN $autoPtx $outbase $mat_atlas2fa $tmpDir $fa
  fi
done




if [ $keep_tmp -eq 1 ]
then
  echo "[INFO]  Not removing temp dir $tmpDir"
else
  rm -fR $tmpDir
fi