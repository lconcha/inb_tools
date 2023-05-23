#!/bin/bash

sound_bank=/etc/timidity/freepats.cfg

# Requires timidity to be installed
# assumes we are using $sound_bank instruments.
# Please open that file to see what number each instrument has.


print_help()
{
  echo "
  `basename $0` <file.MID> <instrument_ID> [-save <file.wav>]

Please see the file $sound_bank to get the instrument IDs. 
You only need the three-digit number.

Example 1:
Play the file mozart.MID using a Xylophone.
  a) Open $sound_bank and see that the xylopone is instrument 013_Xylophone.pat in bank0
  b) The command would be:
  `basename $0` mozart.MID 013
  

Example 2:
Play the file bach.MID using an accordion and save to bach_tango.wav.
  a) Open $sound_bank and see that the accordion is instrument 021_Accordion.pat in bank0
  b) The command would be:
  `basename $0` bach.MID 021 bach_tango.wav

LU15 (0N(H4
INB, UNAM
October, 2013

Inspiration from:
https://wiki.archlinux.org/index.php/Timidity

"
}


if [ $# -lt 2 ] 
then
	echo " ERROR: Need more arguments..."
	print_help
	exit 1
fi



declare -i i
i=1
saveWav=0
saveString=""
for arg in "$@"
do
  case "$arg" in
  -h|-help) 
    print_help
    exit 1
  ;;
  -save)
    nextarg=`expr $i + 1`
    eval wav=\${${nextarg}}
    echo "Will save wav file to $wav" 
    saveString="-Ow -o $wav"
  ;;
  esac
  i=$[$i+1]
done




timidity=`which timidity`
if [[ x"$timidity" == "x" ]]
then
	echo "ERROR: timidity not found"
        exit 2
else
	echo "INFO: timidity found at $timidity"
        echo "INFO: Using sound bank at $sound_bank"
fi




MIDI=$1
voiceID=$2
instrument=`grep Tone_000/$voiceID $sound_bank | awk '{print $2}'`

options_string="-x\"bank 0\n0 $instrument\" $saveString"
echo "--> $timidity $options_string $MIDI"
eval $timidity $options_string $MIDI




