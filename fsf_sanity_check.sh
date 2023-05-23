
fsf=$1

hasErrors=0

# Check if output directory is viable
outputDir=`grep "set fmri(outputdir)" $fsf | awk '{print $3}' | sed s/\"//g`
direc=`dirname $outputDir`
if [ -d $direc ]
then
	printf "."
	if [ -d $outputDir ]
	then
	    echo "  WARNING: Output directory exists: $outputDir"
	fi
else
	echo "  ERROR: Cannot find output directory: $direc"
	hasErrors=1
fi


# Check if we have the template
std=`grep "set fmri(regstandard)" $fsf | awk '{print $3}' | sed s/\"//g`
std=${std}.nii.gz
if [ -f ${std} ]
then
	printf "."
else
	echo "  ERROR: Cannot find template: $std"
	hasErrors=1
fi


# Check if we will need an initial loRes
str=`grep "set initial_highres_files" $fsf`
if [ -z "$str" ]
then
	printf "."
else
	initial=`echo $str | awk '{print $3}' | sed s/\"//g`
	initial=${initial}.nii.gz
	if [ -f $initial ]
	then
		printf "."
	else
		echo "  ERROR: Cannot find initial BOLD image: $initial"
		hasErrors=1
	fi

fi


# Check that we have the hiRes T1
t1=`grep "set highres_files(1)" $fsf | awk '{print $3}' | sed s/\"//g`
if [ -z $t1 ]
then
  printf "."
else
  t1=${t1}.nii.gz
  if [ -f ${t1} ]
  then
	  printf "."
  else
	  echo "  ERROR: Cannot find T1 volume: $t1"
	  hasErrors=1
  fi
fi


# Look for all the necessary stimulus files
grep "set fmri(custom" $fsf | while read line
do
	stim=`echo $line | awk '{print $3}' | sed s/\"//g`
  if [[ "$stim" = "dummy" ]]
  then
    continue
  fi
  if [ -f ${stim} ]
	then
		printf "."
	else
		echo "  ERROR: Cannot find Stimulus file: $stim"
		hasErrors=1
	fi
done


# are we doing a high level?
str=`grep "set fmri(level) 1" $fsf`
if [ -z "$str" ]
then
  hiLevel=1
  echo "This is a high-level feat"
else
  hiLevel=0
  echo "This is a low-level feat"
fi



# If high level, how many copes are we dealing with?
if [ $hiLevel -eq 1 ]
then
  nCopes=`grep "set fmri(ncopeinputs)" $fsf | awk '{print $NF}'`
  echo "  There are $nCopes copes"
fi




# Look for all the feat directories (for high level analyses)
if [ $hiLevel -eq 1 ]
then
  echo "  Looking for low level feat directories and copes..."
  grep "set feat_files(" $fsf | while read line
  do
    featDir=`echo $line | awk '{print $3}' | sed s/\"//g`
    if [ -d ${featDir} ]
    then
      printf "    found %s " $featDir
      for cope in $(seq $nCopes)
      do
      if [ -f ${featDir}/stats/cope${cope}.nii.gz ]
	then
	  printf "%d, " $cope
	else
	  let hasErrors=1
	  printf "\n      ERROR: Cannot find cope: %s" ${featDir}/stats/cope${cope}.nii.gz
	fi
      done
      printf "\n"
    else
      echo "  ERROR: Cannot find low level feat directory: $featDir"
      hasErrors=1
    fi
  done
fi



echo $hasErrors

if [ $hasErrors -eq 0 ]
then
	echo ""
	echo "OK: fsf has no errors: $fsf"
else
	echo ""
	echo "ERRORS FOUND. DO not run this fsf: $fsf"
fi


