#!/bin/bash

INdir=$1
OUTname=$2
metodo=$3



print_help() {
echo 
echo "
      Convertir un directorio de DICOMs a nifti, 
      nombrando los archivos de acuerdo al directorio.
      
      Nota: Solamente se vale un directorio de imagenes,
      no un directorio con subdirectorios con imagenes.
      
      Uso:
      
      `basename $0` DICOMdir OUTname [Opciones]

      Opciones:
      -metodo <int> :        1 para usar dcm2nii (default)
                             2 para usar mrtrix's mrconvert
                             El metodo 2 no encuentra los bvals y bvecs en el header de los dicoms.
      -reorientar   :        Reorienta el volumen final para tener la misma orientacion que los atlas de fsl.
      -clobber      :        Sobre-escribir un archivo existente (default es no sobre-escribir).
      -force_incomplete :    Si el volumen es 4D y faltan dicoms, se convertirán los frames que se puedan.
      -max_incomplete <int>: Si faltan mas de n numero de frames, abortar la conversion.
 
     
      Ejemplo 1: `basename $0` /home/lconcha/misDicoms/sujeto001/004_fMRI sujeto04_fMRI -metodo 1 -clobber
      Ejemplo 2: `basename $0` /home/lconcha/misDicoms/sujeto001/005_BRAVO sujeto04_T1 -reorientar

      Luis Concha. INB, UNAM
      Feb, 2010"
}


declare -i index
declare -i nextArg
reorient=0
metodo=1
clobber=0
force_incomplete=0
max_incomplete=0
for arg in "$@"
do

	case "$arg" in
		-h|-help) 
		print_help
                exit 1
		;;
	   -clobber)
		clobber=1
		;;
	   -reorientar)
		reorient=1
		;;
	   -metodo)
		nextArg=${index}+2
		eval metodo=\$$nextArg
                ;;
           -force_incomplete)
		force_incomplete=1
		max_incomplete=100000
		;;
           -max_incomplete)
		force_incomplete=1
		nextArg=${index}+2
		eval max_incomplete=\$$nextArg
		;;
	esac
	index=$[$index+1]
done


do_cmd() 
{
   local l_command=""
   local l_sep=""
   local l_index=1
   while [ ${l_index} -le $# ]; do
   eval arg=\${$l_index}
   l_command="${l_command}${l_sep}${arg}"
   l_sep=" "
   l_index=$[${l_index}+1]
   done
   echo " --> ${log_header} ${l_command}"
   $l_command
}


if [ $# -lt 1 ] 
then
	print_help
	exit 1
fi


if [ $# -lt 3 ] 
then
	metodo=1
fi


# Parsear los argumentos
# Quitar el slash final si existe
INdir=${INdir%/}
# QUitar el sufijo si existe
OUTname=${OUTname%.nii.gz}
OUTname=${OUTname%.nii}


# # check if we have all the dicoms that we will need
# firstDicom=`ls ${INdir}/*.dcm | head -n 1`
# nSlices=`dicomhead $firstDicom | grep slices | awk '{print $NF}'`
# echo $nSlices
# if [ $nSlices -eq 0 ]
# then
#   nSlices=`dicomhead $firstDicom | grep "Images in Acquisition" | awk -F/ '{print $NF}'`
# fi
# echo $nSlices
# nVols=`dicomhead $firstDicom | grep "Temporal Positions" | awk -F/ '{print $NF}'`
# nDicoms=`ls $INdir | wc -l`
# dicomsNeeded=`echo "$nSlices * $nVols" | bc -l`
# dicomsMissing=`echo "$dicomsNeeded - $nDicoms" | bc -l`
# nFullVolumes=`echo "$nDicoms / $nSlices" | bc `
# nMissingVols=`echo "$nVols - $nFullVolumes" | bc -l`
# echo "nSlices      : $nSlices"
# echo "nVols        : $nVols"
# echo "nDicoms      : $nDicoms"
# echo "dicomsNeeded : $dicomsNeeded"
# echo "dicomsMissing: $dicomsMissing"
# echo "nMissingVols:  $nMissingVols"
# echo "max_incomplete: $max_incomplete"



if [ $dicomsMissing -gt 0 ]
then
	nFullVolumes=`echo "$nDicoms / $nSlices" | bc`
        lastGoodDicom=`echo "$nFullVolumes * $nSlices" | bc`
        echo "nFullVolumes: $nFullVolumes"
        echo "lastGoodDicom: $lastGoodDicom"
	if [ $force_incomplete -eq 1 ]
        then
		if [ $nMissingVols -gt $max_incomplete ]
		then
			echo "ERROR: There are too many missing volumes ($nMissingVols). Aborting."
			exit 1
		fi
	        echo "FALTAN DICOMS. Convirtiendo LO QUE SE PUEDA"
		tmpINdir=/tmp/inb_dcm2nii_`random_string`
                mkdir $tmpINdir
                for f in `seq 1 $lastGoodDicom`
                do
			frame=`printf %04.0f $f`
			printf %s .
                	cp ${INdir}/${frame}.dcm $tmpINdir/
                        
                done
	printf "%d \n" $lastGoodDicom
		INdir=$tmpINdir
	else
		echo "ERROR: No existen todos los dicoms necesarios."
	fi
fi




# Check if we already have that file and decide if overwriting
if [ -f ${OUTname}.nii.gz ]
then
  echo "El archivo ${OUTname}.nii.gz ya existe."
  if [ $clobber -eq 1 ]
  then
    echo "Sobre-escribiendo!"
    rm -f ${OUTname}.nii.gz
  else
    echo "Usar switch -clobber para sobre-escribir. Adios!"
    exit 1
  fi
fi


tmpDir=/tmp/inb_dcm2nii_`random_string`
mkdir -p $tmpDir


if [ $metodo -eq 1 ]
then
  do_cmd dcm2nii -o ${tmpDir}/ -n y -g y -d n -f n -r n -x n $INdir
  nii=${tmpDir}/*.nii.gz
  sequence=`basename $INdir`
  echo
  

  bval=`readlink -f ${tmpDir}/*.bval`
  bvec=`readlink -f ${tmpDir}/*.bvec`
  if [ -f $bval -a -f $bvec ]
  then
	echo "This is a DTI file"
	do_cmd mv $bval ${OUTname}.bval
	do_cmd mv $bvec ${OUTname}.bvec
	do_cmd mv ${bvec%.bvec}.nii.gz ${OUTname}.nii.gz
  else
	do_cmd mv $nii ${OUTname}.nii.gz
  fi
fi


if [ $metodo -eq 2 ]
then
	sequence=`basename $INdir`
	do_cmd mrconvert $INdir ${tmpDir}/im.mif
	do_cmd mrconvert ${tmpDir}/im.mif ${tmpDir}/im.nii
        #nii2mnc /tmp/$$_nii.nii	/tmp/$$_mnc.mnc
        #mnc2nii /tmp/$$_mnc.mnc ${OUTdir}/${sequence}.nii
        do_cmd fslmaths ${tmpDir}/im.nii -mul 1 ${OUTname}.nii
        do_cmd mrinfo -grad ${OUTname}.b ${tmpDir}/im.mif
	gzip -v ${OUTname}.nii
  	echo Done.
fi



if [ $reorient -eq 1 ]
then
   echo "Reorientando ..."
   mv ${OUTname}.nii.gz ${tmpDir}/out.nii.gz
   do_cmd fslreorient2std ${tmpDir}/out.nii.gz ${OUTname}.nii.gz
fi

rm -fR $tmpDir $tmpINdir
