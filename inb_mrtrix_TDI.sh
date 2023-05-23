#!/bin/bash
source `which my_do_cmd`


CSD=$1
wm=$2
mask=$3
out_tracks=$4
tdi=$5





#### Defaults
num=500000
voxSize=1
color=""
minlength=10
maxlength=200
#############
print_help()
{
echo "
`basename $0` <CSD.mif> <WM_mask.mif> <mask.mif> <out_tracks.tck> <tdi.mif> [-OPTIONS]

 Options:
  -num <int>                          Number of tracks to calculate (Default=${num})
  -minlength <int>                    Minimum track length (Default=${minlength} mm)
  -maxlength <int>                    Maximum track length (Default=${maxlength} mm)
  -voxSize <float> 
             OR 
           "'"<float float float>"'"  Voxel size of final track density image.
                                      (Default is ${voxSize} mm per side)
  -color                              Add color to the TDI
  -clobber 

 Luis Concha
 INB, Jan 2011

"
}




if [ $# -lt 1 ] 
then
	echo " ERROR: Need more arguments..."
	print_help
	exit 1
fi




clobber=0
declare -i i
i=1
for arg in "$@"
do
  case "$arg" in
    -h|-help) 
      print_help
      exit 1
    ;;
    -num)
      nextarg=`expr $i + 1`
      eval num=\${${nextarg}}
    ;;
    -voxSize)
      nextarg=`expr $i + 1`
      eval voxSize=\${${nextarg}}
    ;;
    -color)
      color="-colour"
    ;;
    -clobber)
      clobber=1
    ;;
    esac
    i=$[$i+1]
done


if [ -f $out_tracks -a $clobber -eq 0 ]
then
  echo "File $out_track already exists. Use -clobber to overwrite. Quitting."
  exit 1
else
  my_do_cmd streamtrack SD_PROB $CSD \
                        -seed $wm \
                        -mask $mask \
                        -num $num \
                        -length $maxlength \
                        -minlength $minlength \
                        $out_tracks
fi


if [ -f $tdi -a $clobber -eq 0 ]
then
  echo "File $tdi already exists. Use -clobber to overwrite. Quitting."
  exit 1
else
  my_do_cmd tracks2prob $color -vox $voxSize $out_tracks $tdi
fi

