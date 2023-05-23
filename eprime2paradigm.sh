#!/bin/bash

print_help()
{
  echo "
  `basename $0` <edat.txt> <outBase> <NombreColumna>

  edat.txt     :  El archivo txt que se genera en e-prime (al exportar)
  outBase      :  El nombre que van a tener los archivos que se van a generar.
                  Por ejemplo, si outBase=/home/lconcha/sujeto11, se generaran tantos archivos
                  con ese nombre, seguido de _nombreDeCategoria.times como haya categorias.
  NombreColumna : El nombre de la columna en el archivo edat.txt que menciona los nombres de 
                  las distintas categorias de estimulos o condiciones del paradigma.


  Ejemplo  : El paradigma incluye dos categorias de sonido, <MUSICA> y <RUIDO>, y el nombre de la
             columna que lo menciona en el archivo <paradigma.txt> dice <CATEGORIAsonica>.
             Queremos generar los archivos pertinentes para el <sujeto01> y colocar los datos en
             la direccion </home/lconcha/fMRI/>
             Por lo tanto, pondriamos el comando:

             `basename $0` paradigma.txt /home/lconcha/fMRI/sujeto01 CATEGORIAsonica

             Al concluir, descubriremos en /home/lconcha/fMRI los archivos:
               sujeto01_MUSICA.times
               sujeto01_RUIDO.times

  
  Luis Concha
  INB
  Enero 2011			
"
}



if [ $# -lt 3 ] 
then
  echo " ERROR: Necesito mas argumentos..."
  print_help
  exit 1
fi


flipOptions=""
for arg in "$@"
do

	case "$arg" in
		-h|-help|-ayuda) 
	           print_help
		   exit 1
	 ;;
	esac
	index=$[$index+1]
done



txt=$1
outbase=$2
columnName=$3

jobfile=/tmp/jobfile_$$.m

echo "addpath /home/lconcha/tools" > $jobfile
echo "addpath /home/lconcha/noelsoft/MatlabTools/lconcha" >> $jobfile
echo "paradigm = eprime2paradigm('$txt','$columnName','$outbase',false,false)" >> $jobfile

cat $jobfile
matlab -nodisplay < $jobfile

rm $jobfile

