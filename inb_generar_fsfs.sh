#!/bin/bash




print_help()
{
  echo "
  `basename $0` <orig.fsf> <niifName>

  Options:
    -origDir <originalPathToFiles>
    -newDir <newPathToFiles>
    -destDir <pathToSaveFSF>
    -IDtochange <ID>
    -newID <newID>
"
}



#############################################
# Parse arguments                           #
#############################################
if [ $# -lt 1 ] 
then
	echo "Para usar:"
	print_help
	exit 1
fi



hasOrigin=0
hasNewDir=0
hasID=0
hasSujetosDir=0
hasnewFsf=0
hasOrig_fsf=0
hasFsf=0
hasNewID=0
hasDestDir=0
verbose=0
declare -i index
index=1
flipOptions=""
for arg in "$@"
do

  case "$arg" in
    -h|-help) 
      print_help
      exit 1
    ;;
    -origDir)
      nextarg=`expr $index + 1`
      eval origDir=\${${nextarg}}
      hasOrigin=1
    ;;
    -newDir)
      nextarg=`expr $index + 1`
      eval newDir=\${${nextarg}}
      hasNewDir=1
    ;;
    -destDir)
      nextarg=`expr $index + 1`
      eval destDir=\${${nextarg}}
      hasDestDir=1
    ;;
    -IDtochange)
      nextarg=`expr $index + 1`
      eval IDtochange=\${${nextarg}}
      hasID=1
    ;;
    -newID)
      nextarg=`expr $index + 1`
      eval newID=\${${nextarg}}
      hasNewID=1
    ;;

    -newfsf)
      nextarg=`expr $index + 1`
      eval fsf=\${${nextarg}}
      hasnewFsf=1
    ;;
    -orig_fsf)
      nextarg=`expr $index + 1`
      eval orig_fsf=\${${nextarg}}
      hasOrig_fsf=1
    ;;
    -verbose)
      verbose=1
    ;;
    esac
index=$[$index+1]
done

if [ $hasFsf -eq 0 ]
then
  fsfsToChange=${sujetosDir}/*/*.fsf
else
  fsfsToChange=$fsf
fi	


if [ $verbose -gt 0 ]; then
echo "  original fsf:  $orig_fsf"
echo "
       hasOrigin:     $hasOrigin
       origDir:       $origDir
       hasNewDir:     $hasNewDir
       newDir:        $newDir
       hasID:         $hasID
       hasNewID:      $hasNewID
       newID:         $newID
       hasDestDir:    $hasDestDir
       destDir:       $destDir
       IDtochange:    $IDtochange
"
fi




orig=$1
niifname=$2

if [ -z $destDir ]
then
  echo "Please use the -destDir switch. Bye."
  exit 1
fi







declare -i i
i=0

originalfsf=`basename $orig`
newfsf=${destDir}/${originalfsf}


  nii=$niifname
  if [ -f $nii ]
  then
	nFrames=`fslinfo $nii | grep ^dim4 | awk '{print $2}'`
        echo " there are $nFrames frames" 
	if [ $nFrames -gt 100 ]
	then

		printf "\t Copying %s\tto\t%s\t(%d frames)\n" $orig $newfsf $nFrames
		sed  s/"set fmri(npts) .*"/"set fmri(npts) $nFrames"/ < $orig > $newfsf
		if [ $hasNewID -gt 0 ]; then
                  echo "Changing ID from $IDtochange to $newID"
		  sed -i s/$IDtochange/$newID/g ${newfsf} 
		fi
		if [ $hasNewDir -gt 0 ]; then
		  echo "Changing directory from $origDir to $newDir"
		  sed -i s,"$origDir","$newDir",g ${newfsf}
		fi
		echo Sanity check
		fsf_sanity_check.sh ${newfsf} > $$.report
		fsfOK=`grep "fsf has no errors" $$.report`
		
		if [ -z "$fsfOK" ]
		then
		    cat $$.report
		else
		    echo "  OK: this fsf has no errors: ${newfsf}"
		fi
		rm -f $$.report

	else
		printf "Subject %s has less than 100 frames in time dimension.\n" ${newfsf} 
		
	fi
  else
	printf "ERROR: Could not find file %s\n" $nii
  fi


