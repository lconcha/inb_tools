#/bin/bash
source `which my_do_cmd`
# Help function
function help() {
		echo "
		Prepare the BRAVO SPGR images for freesurfer
		
		To use: `basename $0` <spgr.mnc.gz> <spgr_readyForFS.mnc.gz>
		
		Luis Concha
		INB, UNAM
		August 2010
		
		"
		exit 1
}



# ------------------------
# Parsing the command line
# ------------------------
if [ "$#" -lt 2 ]; then
		echo "[ERROR] - Not enough arguments"
		help
fi
orig=$1
final=$2
# do not put the .gz in final



if [ -f $orig ]
then
  echo "Original file found: $orig"
else
  echo "ERROR: Cannot find file $file"
  exit 1
fi
if [ -f $final ]
then
  echo "Final file found:    $final"
  echo "Will not overwrite. Delete the file if you want to continue".
  exit 1
fi

declare -i index
index=1
crop=0
for arg in "$@"
do
  case "$arg" in
    -h|-help) 
      help
      exit 1
      ;;
    -zmax)
      eval zmax=\$`echo $index +1 | bc -l`
      echo "Will crop to zmax: $zmax"
      crop=1
      ;;
  esac
  index=$[$index+1]
done



# crop if needed
if [ $crop -eq 1 ]
then
    my_do_cmd mincreshape -clobber \
	        -dimrange zspace=0,$zmax \
	        $orig \
	        ${orig%.mnc.gz}_cropped.mnc
    my_do_cmd gzip -v ${orig%.mnc.gz}_cropped.mnc
    croppedName=${orig%.mnc.gz}_cropped.mnc.gz
fi



# # brain extraction
# my_do_cmd mincbet $croppedName ${orig%.mnc.gz} -m -n -f 0.4
# maskName=${orig%.mnc.gz}_mask.mnc


# N3 correction
my_do_cmd spip-nuc_and_clamp.sh ${orig%.mnc.gz}_cropped.mnc.gz -o /tmp/ -force_3T
#-mask $maskName

ls /tmp/${orig%.mnc.gz}*

my_do_cmd mincnlm /tmp/${orig%.mnc.gz}_cropped_nuc.mnc.gz $final

my_do_cmd  gzip $final

rm -f /tmp/*${orig%.mnc.gz}*
rm -f $croppedName $maskName
