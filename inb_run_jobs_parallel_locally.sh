#!/bin/bash
source `which my_do_cmd`

print_help()
{
  echo "
  `basename $0` <jobfile>

  Luis Concha
  INB
  Jan 2011			
"
}


# Check that we have parallel installed
if [ -z `which parallel` ]
then
	echo "Please install parallel before using this script".
        echo " (Note that the parallel in the repository is not GNU Parallel."
        echo " The easiest installation is downloading the .deb from here:
               https://build.opensuse.org/package/binaries?package=parallel&project=home%3Atange&repository=xUbuntu_10.04"
            
        exit 1
fi


if [ $# -lt 1 ] 
then
  echo " ERROR: Please supply a jobfile..."
  print_help
  exit 1
fi





flipOptions=""
for arg in "$@"
do

	case "$arg" in
		-h|-help) 
		print_help
                exit 1
		;;
	esac
	index=$[$index+1]
done





jobfile=$1
echo "I will now run several jobs in parallel".
cat $jobfile
cat $jobfile | parallel -j-1 --eta 


## OLD VERSION
#commandToRun=$2
#nProcs=$3
#export FSLPARALLEL=0
#echo "cat $jobfile | xargs -n1 -P${nProcs} $commandToRun"
#cat $jobfile | xargs --null --delimiter=@ --interactive -r -n1 -P${nProcs} $commandToRun


