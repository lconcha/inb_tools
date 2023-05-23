#!/bin/bash
source `which my_do_cmd`

reverse=0
machine=""


print_help()
{


 echo "`basename $0` <machine> [-options]

 Copia los archivos de /home/inb/`whoami` a una carpeta en /misc:
    /misc/[machine]/`whoami`/nobackup/home_links


 Options:

 -h, -help : Imprime esta ayuda.
 -reverse  : Revierte los efectos de este script
             (regresa los archivos a /home/inb/`whoami`)
             PRECAUCION: Importante especificar la misma [machine] que cuando se corrio de ida este script.

 
LU15 (0n(H4
INB, UNAM
Septiembre 2020
lconcha@unam.mx

"
}

for arg in "$@"
do

   case "$arg" in
    -h|-help) 
      print_help
      exit 1
    ;;
    -reverse)
      reverse=1
    ;;
  esac
done



machine=$1



if [ -z $machine ]
then
 echo ""
 echo "ERROR: Necesitas especificar <machine>"
 echo ""
 print_help
 exit 2
fi



linksdir=/misc/${machine}/`whoami`/nobackup/home_links


if [ $reverse -eq 0 ]
then
echolor cyan "Will make home links in $linksdir"
echo mkdir -p $linksdir

if [ ! -d $linksdir ]
then
 echolor red "ERROR: No existe ni pude crear $linksdir"
 echo        "       Está mal escrito <machine>?"
 echo        "       Revisa la ruta: puede existir $linksdir ?"
 exit 2
fi


for d in `ls -d ~/.*`
do
  dd=`basename $d`
  if [[ "$dd" == . || "$dd" == ".."  || "$dd" == ".tractseg" ]]
  then
    continue
  fi
  echolor yellow "Moving $d to $linksdir"
  rsync -avz --partial --progress --rsh=ssh "$d" $linksdir/
  my_do_cmd mv "$d" "${d}.bak"
  my_do_cmd ln -s $linksdir/"$dd" "$d"
done
fi



if [ $reverse -eq 1 ]
then
  echolor yellow "Regresando archivos al servidor"
  find ~/ -maxdepth 1 -type l | while read link
  do
    if [ ! -f "${link}.bak" -a ! -d "${link}.bak" ]
    then
      echo "[INFO] no bak for $link"
      continue
    fi
    echolor yellow "Restaurando $link"
    my_do_cmd  rm "$link"
    my_do_cmd  mv "${link}.bak" "$link"
    echo ""
  done
  echolor orange   "========================================================================"
  echolor orange   " Por favor borra manualmente la carpeta con la copia de tu home usando:"
  echolor bold     " rm -fR $linksdir"
  echolor orange   "========================================================================"
fi
