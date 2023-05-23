#! /bin/bash
source `which my_do_cmd`

print_help()
{
echo "
`basename $0` <DWIs.nii[.gz]> <encoding.b> <output_ratios>

Obtains the average b=0 volume from the DWIs, based on the
information in encoding.b. It then divides each volume in
DWIs by the average b=0 volume and puts it in output_ratios.

Note that encoding.b is in mrtrix form.

 Luis Concha
 INB, February 2014.
 lconcha@unam.mx

"
}



if [ $# -lt 3 ] 
then
	echo " ERROR: Need more arguments..."
	print_help
	exit 1
fi



dwis=$1
encoding=$2
output_ratios=$3


tmpDir=/tmp/ratios_`random_string`
mkdir $tmpDir

# first we get the b=0 indices
indices=""
while read idx
do
  b=`echo "$indices,$(($idx -1))"`
  #echo $b
  indices=$b
done < <(cat $encoding | awk '{print $4}' | grep -n ^0 | awk -F: '{print $1}' | sed 's/ //g')
zb_indices=${indices:1:${#indices}}


# Get the average b=0 volume
all_b0s=${tmpDir}/b0s.nii
av_b0=${tmpDir}/av_b0
my_do_cmd  mrconvert \
  -coord 3 $zb_indices \
  -datatype Float32 \
  $dwis \
  $all_b0s
my_do_cmd  fslmaths \
  $all_b0s \
  -Tmean \
  $av_b0 -odt float


# obtain the ratios to the average b=0 volume
my_do_cmd  fslmaths \
  $dwis \
  -div $av_b0 \
  $output_ratios -odt float


# clean up
rm -fR $tmpDir