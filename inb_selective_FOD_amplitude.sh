#!/bin/bash


print_help()
{
  echo "
  `basename $0` <fPeaks.nii> <fAmplitudes.nii> <fTracks.tck> \\
                <ofPeaks.nii> <ofAmplitudes.nii> <ofVectors.nii>


 For a given track, select the FODs that have allowed that track to pass
 through each voxel, even in areas of crossing fibres.
 
 Inputs:
 fPeaks      : The peaks image obtained through find_SH_peaks
 fAmplitudes : the amplitudes image obtained through dir2amp
 fTracks     : The track file (.tck)

 Files to write (specify file names): 
 ofPeaks     : The peaks file (indices)
 ofAmplitudes: The amplitudes (of the corresponding FOD peak)
 ofVectors   : The vectors of the particular FOD peaks
               that allowed the track to pass through each voxel.

 Notes:
 Please make sure that your fPeaks file does not contain >3 peaks/voxel.
 File names should use .nii suffix.
 This is a wrapper to a matlab function: inb_selective_FOD_amplitude.m


 LU15 (0N(H4
 INB, UNAM
 Feb 2014.
 lconcha@unam.mx


  Luis Concha
  INB
  Feb 2014			
"
}



if [ $# -lt 6 ] 
then
  echo " ERROR: Need more arguments..."
  print_help
  exit 1
fi




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

	esac
	index=$[$index+1]
done



fPeaks=$1
fAmplitudes=$2
fTracks=$3
ofPeaks=$4
ofAmplitudes=$5
ofVectors=$6


matlabcommand=/home/inb/lconcha/fmrilab_software/MATLAB/R2013a/bin/matlab
$matlabcommand -nodisplay <<EOF
[rPeaks,rAmplitudes,rVectors] = inb_selective_FOD_amplitude(...
                                '$fPeaks', '$fAmplitudes', '$fTracks',...
                                '$ofPeaks', '$ofAmplitudes', '$ofVectors');
EOF

