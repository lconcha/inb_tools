#!/bin/bash
source `which my_do_cmd`


print_help() {
echo 
echo "Genera el mapa de B0 basado en dos imagenes con TE distintos y sus mapas de fase
      
      Uso:
      `basename $0` im_te0.nii.gz te0 im_te1.nii.gz te1 fieldmap_rads.nii.gz
      
      Donde:
      im_te0.nii.gz:   Imagen en 4D de un eco de gradiente con TE corto.
                       El primer frame contiene la imagen de magnitud, 
		       el segundo frame contiene el mapa de fases.
      te0          :   El TE de la primer imagen de eco de gradiente (ej. 8 ms).
      im_te1.nii.gz:   Imagen en 4D de un eco de gradiente con TE no tan corto.
                       El primer frame contiene la imagen de magnitud, 
		       el segundo frame contiene el mapa de fases.
      te0          :   El TE de la primer imagen de eco de gradiente (ej. 11 ms).
      
      fieldmap_rads.nii.gz: El resultado. Es un mapa de B0 con unidades de rads/s.
      
      Luis Concha. INB, UNAM
      Marzo, 2010
      
      
      Basado en las instrucciones de:
      http://www.fmrib.ox.ac.uk/fsl/fugue/feat_fieldmap.html
      
      "
}

declare -i i
i=1
for arg in "$@"
do
   case "$arg" in
	-help)
	  print_help
	  exit 1
	;;
   esac
   i=`expr $i + 1`
done



if [ $# -lt 5 ] 
then
	echo "ERROR, se necesitan 5 argumentos."
	print_help
	exit 1
fi


# parse arguments
im_te0=$1
te0=$2
im_te1=$3
te1=$4
fieldmap_rads=$5


# temp variables
rstring=`random_string`
tmpDir=/tmp/${rstring}
mkdir $tmpDir
tmpBase=${tmpDir}/genPhase_



# Extract the images from the 4D data sets
orig_phase0=${tmpBase}orig_phase0.nii.gz
orig_phase1=${tmpBase}orig_phase1.nii.gz
orig_mag0=${tmpBase}orig_mag0.nii.gz
my_do_cmd fslroi $im_te0 $orig_phase0 1 1 # the phase map of te0
my_do_cmd fslroi $im_te0 $orig_mag0 0 1   # the magnitude image of te0
my_do_cmd fslroi $im_te1 $orig_phase1 1 1 # the phase map of te1


# Obtain a brain mask
my_do_cmd bet2 $orig_mag0 ${tmpBase}mask -m
mask=${tmpBase}mask_mask.nii.gz
mag0_masked=${tmpBase}mask.nii.gz


# get the phase maps in radians
pi=3.14159265
scale=16384 # this is the nBits of the image (14)
phase0_rad=${tmpBase}phase0_rad.nii.gz
phase1_rad=${tmpBase}phase1_rad.nii.gz
my_do_cmd fslmaths $orig_phase0.nii.gz -mul $pi -mul 2 -div $scale $phase0_rad -odt float
my_do_cmd fslmaths $orig_phase1.nii.gz -mul $pi -mul 2 -div $scale $phase1_rad -odt float

# Unwrap the phase maps
phase0_unwrapped_rad=${tmpBase}_phase0_unwrapped_rad.nii.gz
phase1_unwrapped_rad=${tmpBase}_phase1_unwrapped_rad.nii.gz
my_do_cmd prelude -a $mag0_masked -p $phase0_rad -o $phase0_unwrapped_rad
my_do_cmd prelude -a $mag0_masked -p $phase1_rad -o $phase1_unwrapped_rad

# get the field map in rads/s
TEdiff=`echo "$te1 - $te0" | bc`
echo "TEdiff is $TEdiff ms"
my_do_cmd fslmaths $phase1_unwrapped_rad \
  -sub $phase0_unwrapped_rad \
  -mul 1000 \
  -div $TEdiff \
  $fieldmap_rads \
  -odt float
  
 # limpieza
 rm -fR $tmpDir
