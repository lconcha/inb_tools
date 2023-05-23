#!/bin/bash


# PEs
# 1 midi
# 3 violin
# 5 pianist
# 7 speech
# 9 nonvocal
# 11 vocalization
# 13 monkey
# 15 target
# 
# 
# COPEs
# 1 midi
# 2 violin
# 3 pianist
# 4 speech
# 5 nonvocal
# 6 vocalization


print_help()
{
  echo "
  `basename $0` <subjectList.txt> <clusterMask.nii.gz> <clusterID> <outBase> <fileType> <cope_numbers> <lowLevelDir> <featDir>

  Options:

  There are no optios.

  Notes:
  <subjetList.txtc>   : A text file with subject IDs that we will get data from. 
                        They must _all_ have the feat directory finished, and they should all 
                        have been done using the same design.fsf. 
                        Fail to do this correctly and you will get stupid data.
  <clusterMas.nii.gz> : The cluster mask (e.g. cluster_mask_zstat1.nii.gz) from which you want
                        to extract the copes for all subjects. 
                        If you want to get a specific coordinate (e.g. the peak z voxel), then
                        first make a mask containing only one voxel=1 and the rest=0.
  <clusterID>         : If providing a cluster mask, chances are it has more than one cluster that 
                        is significant. Enter the number of the cluster that you want to
                        investigate. It can only handle a single cluster.
                        
  <outBase>           : The base name (full path) onto which the results will be written to.
                        Example: /home/`whoami`/myResults/myExperiment
  <fileType>          : Either cope or pe.
  <cope_nuimbers>     : The copes or pes that you want to plot per subject.
                        IMPORTANT: Put the list between quotes.
  <lowLevelDir>       : The full path where all the feats of all the subjects are saved.
  <featDir>           : The name of the feat directory that each subject has.


  EXAMPLE:

  `basename $0` sujetos53 \\
                ../Nov2011/meanAllCopes53subj.gfeat/cope1.feat/cluster_mask_zstat1.nii.gz \\
                1 \\
                ~/Desktop/tmp/cope/base \\
                cope \\
                \"1 2 3\" \\
                /home/lconcha/fMRI/archivos_sujetos/ \\
                luis_e_loRes.feat
    
  
 ------------------
  Luis Concha
  BRAMS, INB
  May, Nov 2011			
"
}



if [ $# -lt 2 ] 
then
  echo " ERROR: Need more arguments..."
  print_help
  exit 1
fi


declare -i index
index=1
quiet=0
for arg in "$@"
do

	case "$arg" in
		-h|-help) 
		print_help
                exit 1
		;;
                -quiet)
		  quiet=1
		;;
	esac
	index=$[$index+1]
done

sujs=$1
mask=$2
clusterID=$3
outbase=$4
fileType=$5
cope_numbers=$6
lowLevelDir=$7
featDir=$8


tmpDir=/tmp/getCopeData_$$
mkdir $tmpDir


fslmaths $mask -uthr $clusterID -thr $clusterID ${tmpDir}/mask.nii.gz
mask=${tmpDir}/mask.nii.gz



for n in $cope_numbers
do
        printf "%d " $n
	cat $sujs | while read id
	do 
		echo "${lowLevelDir}/${id}/${featDir}/reg_standard/stats/${fileType}${n}.nii.gz" >> ${tmpDir}/lista_${n}
	done
        lista=`transpose_table.sh ${tmpDir}/lista_${n}`
	fslmerge -t ${tmpDir}/merged_cope_${n}.nii.gz $lista
	fslstats -t ${tmpDir}/merged_cope_${n}.nii.gz -k $mask -m > ${tmpDir}/cope_${n}.txt
	transpose_table.sh ${tmpDir}/cope_${n}.txt >> ${tmpDir}/merged.txt
	awk 'BEGIN{s=0;}{s=s+$1;}END{print s/NR;}' ${tmpDir}/cope_${n}.txt >> ${tmpDir}/mean_cope_${n}
	awk '{sum+=$1; sumsq+=$1*$1} END {print sqrt(sumsq/NR - (sum/NR)**2)}' ${tmpDir}/cope_${n}.txt >> ${tmpDir}/std_cope_${n}

done
transpose_table.sh ${tmpDir}/merged.txt > ${outbase}_FULL_copeData.txt

for n in $cope_numbers
do
	cat ${tmpDir}/mean_cope_${n} >> ${tmpDir}/merged_mean_cope_all

	# Use the standard deviation for plots, produces uglier plots.
	#cat ${tmpDir}/std_cope_${n} >> ${tmpDir}/merged_std_cope_all

	# get the standard error of the mean, produces prettier plots
	sd=`cat ${tmpDir}/std_cope_${n}`
        echo "sqrt($sd)" | bc -l >> ${tmpDir}/merged_std_cope_all
        echo $n >> ${tmpDir}/copeNumbers
done


transpose_table.sh ${tmpDir}/copeNumbers >> ${tmpDir}/final
transpose_table.sh ${tmpDir}/merged_mean_cope_all >> ${tmpDir}/final
transpose_table.sh ${tmpDir}/merged_std_cope_all >> ${tmpDir}/final

transpose_table.sh ${tmpDir}/final > ${outbase}_copeData.txt

printf "\n"



xmin=`echo $cope_numbers | awk '{print $1}'`;  xmin=$(($xmin -1))
xmax=`echo $cope_numbers | awk '{print $NF}'`; xmax=$(($xmax +1))

gnuplot << EOF
set terminal postscript
set output "${outbase}_copeData.eps"
set xrange [ $xmin : $xmax ]
set boxwidth 0.5
set style fill solid 0.5 noborder
plot "${outbase}_copeData.txt" with boxerror
EOF

if [ $quiet -eq 0 ]
then
  display ${outbase}_copeData.eps
fi


rm -fR $tmpDir


