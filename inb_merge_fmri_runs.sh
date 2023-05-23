#!/bin/bash
source `which my_do_cmd`
FSLOUTPUTTYPE=NIFTI




print_help()
{
echo "
`basename $0` <file1> <file2> [... filen] <output>

Concatenate several fMRI runs and do motion correction.
All images are corrected taking the first frame of file1 as reference.

The script sends the jobs to the cluster, so use qstat to watch its progress.
The input and output files must resinde somewhere accessible to the cluster.

*** PLEASE gzip the output file once it finishes.

 LU15 (0N(H4
 INB, February 2015.
 lconcha@unam.mx

"
}



if [ $# -lt 3 ] 
then
	echo " ERROR: Need more arguments..."
	print_help
	exit 1
fi





filesToConcatenate=""
index=0
for arg in "$@"
do
   filesToConcatenate=`echo $filesToConcatenate $arg`
   if [ $index -eq 0 ]
   then
    firstFile=$arg
   fi
   index=$(($index+1))
done


lastarg=`expr $#`
eval outFile=\${${lastarg}}

filesToConcatenate=${filesToConcatenate%${outFile}}

echo "files to concatenate: $filesToConcatenate" 
echo "first file is: $firstFile" 
echo outfile is $outFile


tmpDir=./tmp_`random_string`/
mkdir $tmpDir


echo "creating links" 
index=0
for f in $filesToConcatenate
do
  imln `readlink -f $f` $tmpDir/full_`zeropad $index 6`.nii
  index=$(($index +1))
done



echo " Extracting A0"
A0=$tmpDir/A0.nii
my_do_cmd fslroi $tmpDir/full_000000.nii $A0 0 1


echo " submitting mcflirt jobs" 
mc_job=$tmpDir/mc.job
for f in $tmpDir/full_*
do
   echo "mcflirt -in $f -reffile $A0" >> $mc_job
done
mc_job_id=`fsl_sub -N mc -t $mc_job -l $tmpDir`


merge_job=$tmpDir/merge.jobs
echo "fslmerge -t $outFile $tmpDir/full_*_mcf.nii" >> $merge_job
echo "rm -fR $tmpDir" >> $merge_job
fsl_sub -j $mc_job_id -t $merge_job -N merge -l $tmpDir




# # 
# # # extract first frames
# # index=0
# # for f in $filesToConcatenate
# # do
# #    my_do_cmd fslroi $f $tmpDir/firstFrame_`zeropad $index 6` 0 1
# #    index=$(($index+1))
# # done
# # 
# # 
# # # create a job file for intra-session motion correction
# # index=0
# # for f in $filesToConcatenate
# # do
# #     echo "mcflirt -in $f -reffile $tmpDir/firstFrame_`zeropad $index 6` -out $tmpDir/mc_`zeropad $index 6` -mats" >> $tmpDir/mc.job
# #     index=$(($index+1))
# # done
# # mc_jid=`fsl_sub -t $tmpDir/mc.job -l $tmpDir`
# # echo "Submitting job files to do mcflirt to cluster: $mc_jid" 
# # 
# # 
# # # create a job file for between-session registration
# A0mat0=$tmpDir/mat_000000_to_0.mat
# echo "1 0 0 0" > $A0mat0
# echo "0 1 0 0" >> $A0mat0
# echo "0 0 1 0" >> $A0mat0
# echo "0 0 0 1" >> $A0mat0
# 
# # index=0
# # firstFrame=$tmpDir/firstFrame_`zeropad 0 6`
# # for f in $tmpDir/firstFrame_*
# # do
# #     if [ $index -gt 0 ]
# #     then
# #       moving=$tmpDir/firstFrame_`zeropad $index 6`
# #       echo "flirt -ref $firstFrame -in $moving -omat $tmpDir/mat_`zeropad $index 6`_to_0.mat  -dof 6" >> bs.job
# #     fi
# #     index=$(($index+1))
# # done
# # bs_jid=`fsl_sub -t $tmpDir/bs.job -l $tmpDir`
# # echo "Submitting between-session registration jobs to cluster: $bs_jid" 
# # 
# 
# 
# 
# nDirs=`ls $tmpDir/full* | wc -l`
# A0=$tmpDir/A0.nii
# my_do_cmd fslroi $tmpDir/full_000000 $A0 0 1
# frame=0
# dindex=0
# for d in `seq 0 $nDirs`
# do
#   findex=0
#   dd=$tmpDir/mc_`zeropad $d 6`.mat
#   for f in ${dd}/MAT*
#   do
#     N_to_0=$tmpDir/mat_`zeropad $d 6`_to_0.mat
#     mcMat=$f
#     frameMat=$tmpDir/mat_frame_`zeropad $frame 6`.mat
#     thisFrame=${tmpDir}/frame_`zeropad $frame 6`
#     thisFull=$tmpDir/full_`zeropad $dindex 6`
#     my_do_cmd  convert_xfm -omat $frameMat -concat $mcMat $N_to_0
#     my_do_cmd  fslroi $thisFull $thisFrame $findex 1
#     my_do_cmd  flirt -in $thisFrame -ref $A0 -applyxfm -init $frameMat
#     frame=$(($frame +1))
#     findex=$(($findex +1))
#   done
#   dindex=$(($dindex +1))
# done

# create a clean-up job
# echo " echo rm -fR $tmpDir" > $tmpDir/clean.job
# echo "Submitting clean-up job"
# fsl_sub -j $mc_jid -j $bs_jid -t $tmpDir/clean.job

# A=/datos/fourier2/lauveri/Marina/25.nii
# B=/datos/fourier2/lauveri/Marina/34.nii
# 
# 
# A0=A0.nii
# B0=B0.nii
# 
# #fslroi $A $A0 0 1
# fslroi $B $B0 0 1
# 
# #fsl_sub -N mcA mcflirt -in $A -reffile $A0 -out A_mc.nii -mats
# #fsl_sub -N mcB mcflirt -in $B -reffile $B0 -out B_mc.nii -mats
# 
# flirt -ref $A0 -in $B0 -omat b0_a_A0.mat -dof 6
# 
# 
# index=0
# for mat in B_mc.nii.gz.mat/MAT_*
# do
#   mc_cat_vol=B_mcCat_`zeropad $index 6`
#   thisMat=B_${index}_to_A0.mat
#   my_do_cmd convert_xfm -omat $thisMat \
#               -concat $mat b0_a_A0.mat
#   my_do_cmd fslroi $B esteVol $index 1
#   my_do_cmd flirt -ref $A0 \
#       -in esteVol \
#       -applyxfm -init $thisMat \
#       -out $mc_cat_vol
#   index=$(($index+1))
# done
# 
# 
# my_do_cmd fslmerge -t B_mcCat B_mcCat_*




