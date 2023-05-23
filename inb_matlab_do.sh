#!/bin/bash

#################
# CONFIGURATION #
#################
# Tell this program what command you usually run to open matlab
# matlabBIN=matlab13alt
matlabBIN=/home/inb/soporte/fmrilab_software/MatlabR2018a/bin/matlab
#/home/inb/lconcha/fmrilab_software/MATLAB/Matlab13-alt/bin/matlab
###############################################################

# Prepare a job file that we will feed to matlab.
job=/tmp/job_$$.m
echo "disp('Welcome to Matlab');" > $job





declare -i i
i=1
declare -i v
v=1
for arg in "$@"
do
# 	eval arg=\$${index}
    case "$arg" in
	-help)
		echo
		echo "  matlab_do: Perform Matlab operations on Nifti files."
		echo "  Because sometimes fslmaths just does not cut the cheese...."
		echo
		echo "  Use: matlab_do.sh -input input2.nii [-input input2.nii [-input input3.nii]] \\"
		echo "                    -output output.nii -command \"matlabExpression\""
        echo
		echo "  matlabExpression must be identical to what you would write inside matlab."
		echo "    The input mnc files get renamed to variables called v[n] where ""n"" is"
		echo "    the number of the input."
		echo "  Whatever you want to ouptut from your computations must be in a variable"
		echo "    called [result]"
		echo "  Example: "
		echo "     matlab_do.sh -input a.nii -input b.nii -output ab.nii \\"
		echo "                  -command \"result=v1+v2;\""
	   echo "     --> this will sum images a.nii and b.nii and write the result in ab.nii"
		echo "     Certainly, this example is better suited for minccalc, but you get the point."
		echo "  Example 2:"
		echo "     matlab_do.sh -input a.nii -output out.nii \\"
		echo "     -command \"v1=v1+2;v1(:,:,10)=zeros(size(v1,1),size(v1,2),1)+3;result=v1;\""
		echo "     --> This will add a 3 to all the volume and replace the 10th slice of a.nii"
		echo "         with the value 3 (all the slice). The result is in out.nii"
		echo
		echo "  Luis Concha. Noel Lab. BIC, MNI. McGill. November 2008 and INB, UNAM, 2012."
		echo "  lconcha@gmail.com"
		echo
		exit 1
		;;
	-input)
		nextarg=`expr $i + 1`
		eval infile=\${${nextarg}}
		# Tell matlab that we will load this file.
	    #infile=/tmp/job_$$_infile_${i}.nii
	    echo "[hdr,v${v}] = niak_read_nifti('${infile}');" >> $job
		v=`expr $v + 1`
	    ;;
	-command)
		 nextarg=`expr $i + 1`
	    eval command=\${${nextarg}}
		;;
	-output)
		nextarg=`expr $i + 1`
	    eval output=\${${nextarg}}
	    ;;

    esac
    i=`expr $i + 1`
done


# Check if help is needed
if [ $# -lt 3 ]
then
	 echo "  Use: matlab_do.sh -input input2.nii [-input input2.nii [-input input3.nii]] \\"
    echo "                    -output output.nii -command \"matlabExpression\""
    echo
    echo "  Use matlab_do.sh -help for more information."
    exit 1
fi


# Finish writing the matlab job file
#echo "result = ${command};" >> $job
echo "${command}" >> $job
echo "hdr.file_name = '$output';" >> $job
echo "niak_write_nifti(hdr,result);" >> $job

# Run the job!
cat $job
$matlabBIN -nodisplay < ${job}


# Remove the job file, we don't need it anymore.
rm -f $job
