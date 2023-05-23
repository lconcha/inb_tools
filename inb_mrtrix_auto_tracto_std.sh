#!/bin/bash
source `which my_do_cmd`
fakeflag=""
export FSLOUTPUTTYPE=NIFTI



## Defaults ################################
autoPtx=/misc/mansfield/lconcha/autoPtx
tckIN=""
outbase=""
## End Defaults ###############################


help() {
echo "
`basename $0` [options] <-tck tracks_in_MNI_space> <-outbase prefix>

Options:

-autoPtx </full/path/to/autoPtx/protocols> 
         Default is $autoPtx



Filter a full tractogram that is in MNI space according to autoPtx protocols.
This is an adaptation of autoPtx for fsl, which is available at:
  http://fsl.fmrib.ox.ac.uk/fsl/fslwiki/AutoPtx


You can copy the autoPtx protocols available on the fsl wiki or the default local 
installation and modify the protocols there to add/remove/edit specific fiber bundles.


To normalise a tractogram to MNI space, use the command:
  inb_mrtrix_tck2atlas.sh


LU15 (0N(H4
September, 2016
INB, UNAM
lconcha@unam.mx

"
}




#
for arg in "$@"
do
  case "$arg" in
  -h|-help) 
    help
    exit 1
  ;;
    -tck)
    tckIN=$2
    shift;shift
    echo "    tckIN is $tckIN"
   ;;
  -outbase)
    outbase=$2
    shift;shift
    echo "    outbase is $outbase" 
  ;;
  -autoPtx)
    autoPtx=$2
    shift;shift
    echo "    autoPtx is $autoPtx"
  ;;
  esac
done


## Argument checks
if [ -z "$tckIN" ]
then
  echo "ERROR: You must supply -tck"
  help
  exit 2
fi
if [ -z $outbase ]; then echo "Please supply -outbase";help;exit 2;fi
##### End argument checks


# find the structures and the atlas
structures=`ls -1 $autoPtx/protocols`
atlas=${FSLDIR}/data/standard/FMRIB58_FA_1mm.nii.gz


# Create temp directory
tmpDir=/tmp/auto_tracto_$$_tmpDir
mkdir $tmpDir







filter(){
  st=$1
  tckIN=$2
  autoPtx=$3
  outbase=$4
  tmpDir=$5
  seed=${autoPtx}/protocols/${st}/seed.nii.gz
  target=${autoPtx}/protocols/${st}/target.nii.gz
  exclude=${autoPtx}/protocols/${st}/exclude.nii.gz
  stop=${autoPtx}/protocols/${st}/stop.nii.gz
  summary=${outbase}_summary.txt

#   if [ -f ${autoPtx}/protocols/${st}/invert ]
#   then
#     invert=1
#   else
#     invert=0
#   fi
  echo "  Filtering full tractogram to retreive structure $st
            seed:    $seed
            target:  $target
            exclude: $exclude
            stop:    $stop"
#             invert:  $invert"

  my_do_cmd $fakeflag tckedit -force \
            $tckIN \
            ${outbase}_f_${st}.tck \
            -include $seed \
            -include $target \
            -exclude $exclude
 nTcks=`tckinfo -count ${outbase}_f_${st}.tck | grep "actual count" | awk '{print $NF}'`  
 echo "$st $nTcks" >> $summary
}


structures=`ls -1 $autoPtx/protocols`
for st in $structures
do
  echo "Working on $st"
  filter $st $tckIN $autoPtx $outbase $tmpDir
done





rm -fR $tmpDir