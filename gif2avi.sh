#!/bin/bash


print_help(){
  echo "
`basename $0` <input.gif> <output.avi> [options]

  Options:
  -framerate <int>  Default is 10
  -scale 
"  
}


if [ $# -lt 2 ] 
then
  echo " ERROR: Necesito mas argumentos..."
  print_help
  exit 1
fi







gif=$1
avi=$2
framerate=10



options=""
for arg in "$@"
do

	case "$arg" in
		-h|-help|-ayuda) 
	           print_help
		   exit 1
	 ;;
		-framerate)
		      nextarg=`expr $index + 2`
		      eval framerate=\${${nextarg}}
	  ;;
		-geometry)
		      nextarg=`expr $index + 2`
		      eval geometry=\${${nextarg}}
		      options="$options -s $geometry"
	  ;;
	esac
	index=$[$index+1]
done


options="$options -r $framerate"


echo convert $gif convtmp%05d.jpg
convert $gif convtmp%05d.jpg

echo ffmpeg -i convtmp%05d.jpg $options -y -an $avi 
ffmpeg -i convtmp%05d.jpg $options -y -an $avi 

rm -f convtmp*.jpg



