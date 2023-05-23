#!/bin/bash

eprime=$1
times=$2


print_help()
{
echo "
`basename $0` <eprime.txt> <outbase> <sideYes>

Extract the stimulus onset and duration from an e-prime txt file.

<eprime.txt> : the eprime txt file
<outbase>    : suffix for outputs.
<sideYes>    : left or right (side that was used to answer YES)

Extremely important:
This approach only works for paradigms with a list of events.

I am certain it only works for Sternberg's paradigm. Copy and edit for
other paradigms, as needed. It uses a completely different approach
than the one I did for Circe, as this one does not have a playlist.

It will specifically look for hard-coded strings, 
so it will most likely NOT work for anything else.

 LU15 (0N(H4
 INB, October 2014.
 lconcha@unam.mx

"
}



if [ $# -lt 3 ] 
then
	echo " ERROR: Need more arguments..."
	print_help
	exit 1
fi




# Remove binary portions in file, and make a clean text file.
cat $eprime | tr -d '\000' > /tmp/stern_$$_eprime_a.txt
tr -cd '[:print:]\n'  < /tmp/stern_$$_eprime_a.txt > /tmp/stern_$$.txt


# find start of paradigm
firstOnset=`grep "TextDisplay2.OnsetTime" /tmp/stern_$$.txt | awk -F: '{print $2}' | tr -d "\015" | sed 's/ //g'`
echo "  First onset: $firstOnset"


# find the onset time and duration of each stimulus.
for stage in COD RET PRB
do
  grep "${stage}.*\.OnsetTime" /tmp/stern_$$.txt \
   | awk '{print $2}' > /tmp/stern_$$_${stage}_onset
  grep "${stage}.*\.Duration:" /tmp/stern_$$.txt \
   | awk '{print $2}' >  /tmp/stern_$$_${stage}_duration
done


# find the response and correct response.
grep "PRB.*\.RESP:" /tmp/stern_$$.txt \
  | awk '{print $2}' >  /tmp/stern_$$_resp
grep "PRB.*\.CRESP:" /tmp/stern_$$.txt \
  | awk '{print $2}' >  /tmp/stern_$$_cresp




# Create a txt file with ones.
nStims=`wc -l /tmp/stern_$$_${stage}_onset | awk '{print $1}'`
echo "  nStims = $nStims"
for s in `seq 1 $nStims`
do
  echo 1 >> /tmp/stern_$$_ones
done


# now we turn ms into seconds. 
# note the -v FO that passes the first onset to awk.
for stage in COD RET PRB
do
    gawk -v FO=$firstOnset '{print (($1 - FO) / 1000)}' /tmp/stern_$$_${stage}_onset > /tmp/stern_$$_${stage}_onsetSec
    gawk '{print ($1 / 1000)}' /tmp/stern_$$_${stage}_duration > /tmp/stern_$$_${stage}_durationSec
    paste /tmp/stern_$$_${stage}_onsetSec /tmp/stern_$$_${stage}_durationSec /tmp/stern_$$_ones > ${times}_${stage}.times
done

# and we organize the responses.
grep "PRB.*\.RESP" /tmp/stern_$$.txt  | awk '{print $2}' | while read resp
do
  if [[ $resp = "b" ]]
  then
    #echo "orig is $resp change to a"
    echo "a" >>  /tmp/stern_$$_respM
  elif [[ $resp = "c" ]]
  then
    #echo "orig is $resp change to d"
    echo "d" >> /tmp/stern_$$_respM
  else
    #echo "orig is EMPTY change to x"
    echo "x" >> /tmp/stern_$$_respM
  fi
done 

# check the laterality of response
side=$3
if [[ $side = "right" ]]
then
   echo "  side for Yes is right"
  cat /tmp/stern_$$_respM | while read resp
  do
    if [[ $resp = "a" ]]
    then
      echo "d" >> /tmp/stern_$$_respM2
    elif [[ $resp = "d" ]]
    then
      echo "a" >> /tmp/stern_$$_respM2
    fi
  done
  rm /tmp/stern_$$_respM
  mv /tmp/stern_$$_respM2 /tmp/stern_$$_respM
elif [[ $side = "left" ]]
then
  echo "  side for Yes is left"
else
  echo "ERROR: Did not understand side, has to be left or right"
  rm /tmp/stern_$$*
  exit 2
fi

grep "PRB.*\.CRESP" /tmp/stern_$$.txt  | awk '{print $2}' > /tmp/stern_$$_cresp
paste /tmp/stern_$$_respM /tmp/stern_$$_cresp | awk '{ print ($1 == $2) ? "correct" : "incorrect" }' > /tmp/stern_$$_score
paste /tmp/stern_$$_respM /tmp/stern_$$_cresp /tmp/stern_$$_score > ${times}.score

nCorrect=`grep $'\tcorrect' ${times}.score | wc -l`
echo "  Number of correct responses: $nCorrect"

awk '{print $1,$2}' ${times}_COD.times > /tmp/stern_$$_summaryA
awk '{print $1,$2}' ${times}_RET.times > /tmp/stern_$$_summaryB
awk '{print $1,$2}' ${times}_PRB.times > /tmp/stern_$$_summaryC
paste /tmp/stern_$$_summary* ${times}.score | awk -v OFS='\t' '{print $1,$2,$3,$4,$5,$6,$9}'


rm /tmp/stern_$$*














# # Note that this approach only works for paradigms with only
# # one list of stimuli.
# stimNumber=0
# prevStage=""
# while read line;
# do
#   if [[ $line =~ TextDisplay2.OnsetTime.* ]]
#   then
#     onset=`echo $line | awk -F: '{print $2}' | tr -d "\015"`
#     firstOnset=$onset
#     continue
#   fi
#   if [[ $line =~ .[0-9]\.OnsetTime:.* ]]
#   then
#     onset=`echo $line | awk -F: '{print $2}' | tr -d "\015"`
#   fi
#   if [[ $line =~ .....Duration:.* ]]
#   then
#     duration=`echo $line | awk -F: '{print $2}' | tr -d "\015"`
#   fi
#  stage=${line:0:3}
#  ePrimeStimNum=${line:3:2}
#  case $stage in
#     PRB)
#       if [[ $line =~ .[0-9]\.RESP:.* ]]
#       then
# 	resp=`echo $line | awk '{print $2}' | tr -d "\015" | sed 's/ //g'`
#         case $resp in
# 	  a|b|c|d)
# 	      dummyVar=1
# 	  ;;
# 	  *)
#            resp=X
# 	  ;;
# 	esac
#       fi
#       if [[ $line =~ .[0-9]\.CRESP:.* ]]
#       then
# 	Cresp=`echo $line | awk  '{print $2}' | tr -d "\015" | sed 's/ //g'`
#         echo "$Cresp - $line"
#       fi
#     ;;
#     COD|RET)
#      dummyVar=1
#     ;;
#     *)
#       continue
#     ;;
#   esac
# 
#   if [[ "$stage" == "$prevStage" ]]
#   then
#       continue
#   else
#       relOnsetSec=`echo "$(($onset - $firstOnset)) / 1000" | bc -l`
#       durationSec=`echo "$duration / 1000" | bc -l`
#       echo $stimNumber ${line:0:5} $ePrimeStimNum $resp $Cresp
#       prevStage=$stage
#       stimNumber=$(($stimNumber +1))
#   fi
#   
# 
# 
# 
# done < <(cat /tmp/stern_$$_eprime.txt)




#   if [[ $line =~ .5Duration:.* ]]
#   then
#     duration=`echo $line | awk -F: '{print $2}' | tr -d "\015"`
#   fi
#   if [[ $line =~ .*LogFrame.End.* ]]  
#   then
#     relOnsetSec=`echo "$(($onset - $firstOnset)) / 1000" | bc -l`
#     durationSec=`echo "$duration / 1000" | bc -l`
#     echo $stimNumber $category $relOnsetSec $durationSec 1 >> /tmp/circe_$$_data.txt
#     prevNumber=$stimNumber
#   fi
#   if [[ $line =~ .*Level:.1.* ]]
#   then
#     break
#   fi


# Find out how many categories we have and write the files.
# awk '{print $2}' /tmp/circe_$$_data.txt | sort | uniq | while read thisCat
# do
#   grep $thisCat /tmp/circe_$$_data.txt | awk '{print $3,$4,$5}' > ${times}_$thisCat.times
#   nEvents=`wc -l ${times}_$thisCat.times | awk '{print $1}'`
#   echo "  $nEvents ${times}_$thisCat.times"
# done




