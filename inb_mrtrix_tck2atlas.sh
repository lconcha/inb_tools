#!/bin/bash
source `which my_do_cmd`


atlas=${FSLDIR}/data/standard/FMRIB58_FA_1mm.nii.gz
tmpDir=/tmp/warptck_$$



help() {
echo "
`basename $0` [options] -fa fa.image -tck_native .tck -tck_atlas out.tck
                        

Options

-help
-warp <native2atlasWarp.mif>     Provide the non-linear warp native2atlas
-atlas <atlas.image>             Default is $atlas
-fa2atlas <outbase>              Prefix for files created by mrregister



LU15 (0N(H4
September, 2016
INB, UNAM
lconcha@unam.mx

"
}


if [ $# -lt 6 ] 
then
  echo " ERROR: Need more arguments..."
  help
  exit 1
fi



fa2atlas=${tmpDir}/fa2atlas
for arg in "$@"
do
  case "$arg" in
  -h|-help) 
    help
    exit 1
  ;;
  -fa)
    fa=$2
    shift;shift 
    echo "    fa  is $fa" 
  ;;
  -tck_native)
    tck_native=$2
    shift;shift 
    echo "    tck_native  is $tck_native" 
  ;;
  -tck_atlas)
    tck_atlas=$2
    shift;shift 
    echo "    tck_native  is $tck_atlas" 
  ;;
  -warp)
    warp=$2
    shift;shift 
    echo "    Warp field  is $warp" 
    ;;
 -atlas)
    atlas=$2
    shift;shift 
    echo "    Atlas  is $atlas" 
    ;;
 -fa2atlas)
    fa2atlas=$2
    shift;shift 
    echo "    fa2atlas  is $fa2atlas" 
    ;;
  esac
done


mkdir $tmpDir

# make sure that the atlas has values in range [0 1]
atlasmax=`mrstats -output max $atlas`
atlas_to_use=${tmpDir}/atlas.mif
my_do_cmd mrcalc $atlas $atlasmax -div $atlas_to_use



## Registration to atlas
if [ ! -z "$warp" ]
then
  echo "  Skipping registration. Warp provided is $warp"
else
  my_do_cmd mrregister $fa \
                       $atlas_to_use \
                       -info \
                       -transformed ${fa2atlas}_transformed.mif \
                       -nl_warp ${fa2atlas}_warp_fromAtlas.mif ${fa2atlas}_warp_toAtlas.mif
  warp=${fa2atlas}_warp_toAtlas.mif
fi


if [ ! -f $warp ]
then
  echo " FATAL ERROR: Cannot find warp file $warp"
  exit 2
fi


## Transform the tracks
my_do_cmd tcknormalise $tck_native $warp $tck_atlas


rm -fR $tmpDir