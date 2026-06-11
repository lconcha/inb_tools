#!/bin/bash
source `which my_do_cmd`

help() {
  echo ""
  echo "Usage:"
  echo "`basename $0` tck criteria indicesOUT tckOUT"
  echo ""
  echolor green "Description:"
  echo "Filter a tractogram and obtain the indices of the selected streamlines"
  echo "The idea comes from: https://community.mrtrix.org/t/individual-streamline-index-included-in-tck-file/1104"
  echo ""
  echo "tck:          Input tck file"
  echo "criteria:     Criteria for selecting tracks (e.g., -include, -exclude, etc.)"
  echo "              Wrap your criteria around single quotes to ensure it's treated as a single argument."
  echo "indicesOUT:   Output file for indices of tracks in tck that pass the criteria (zero-based)"
  echo "tckOUT:       Output tck file for selected tracks from tck"
  echo ""
  echo "LU15 (0N(H4"
  echo "INB UNAM"
  echo "June 2026"
  echo "lconcha@unam.mx"
  exit 1
}


tck=$1
criteria="$2"
indicesOUT=$3
tckOUT=$4

isOK=1
for f in $tck; do
  if [[ ! -f "$f" ]]; then
    echolor red "File not found: $f"
    isOK=0
  fi
done


if [[ -z "$tck" || -z "$criteria"  || -z "$tckOUT" ]]; then
  echolor red "Missing required arguments."
  help
  exit 1
fi

if [[ $isOK -ne 1 ]]; then
  echolor red "One or more input files are missing. Please check the paths and try again."
  help
  exit 1
fi

tmpDir=$(mktemp -d)

weights="$tmpDir/weights.txt"
weightsOUT="$tmpDir/weightsOUT.txt"
nTracks=$(tckinfo -count "$tck" | grep "actual count" | awk -F: '{print $2}' | sed 's/[^0-9]//g')
echolor green "Number of tracks in input file: $nTracks"

# create a dummy weights file with all weights set to 1
seq 1 "$nTracks"  > "$weights"


# nthreads MUST BE ZERO or indexing goes to hell.
my_do_cmd tckedit -nthreads 0  \
  "$criteria" \
  -tck_weights_in $weights \
  -tck_weights_out $weightsOUT \
  $tck \
  $tckOUT

# print out the indices of the selected tracks (convert one-based to zero-based by subtracting 1)
tr ' ' '\n' < "$weightsOUT" | awk '{print $1 - 1}' > "$indicesOUT" 
nSelected=$(wc -l < "$indicesOUT")
echolor green "Number of selected tracks: $nSelected"

rm -rf "$tmpDir"