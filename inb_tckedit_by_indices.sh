#!/bin/bash
source `which my_do_cmd`

help() {
  echo ""
  echo "Usage:"
  echo "`basename $0` tck1 indices weightsOUT tck1OUT"
  echo ""
  echolor green "Description:"
  echo "Filter a tractogram by a set of streamline indices"
  echo "The idea comes from: https://community.mrtrix.org/t/individual-streamline-index-included-in-tck-file/1104"
  echo ""
  echo "tck1:         Input tck file 1"
  echo "indices:      File containing the indices of streamlines to select"
  echo "              Zero-based indices, one per line." 
  echo "weightsOUT:   Output file for weights of tracks in tck1"
  echo "tck1OUT:      Output tck file for selected tracks from tck1"
  echo ""
  echo "LU15 (0N(H4"
  echo "INB UNAM"
  echo "June 2026"
  echo "lconcha@unam.mx"
  exit 1
}


tck1=$1
indices=$2
weightsOUT=$3
tck1OUT=$4

isOK=1
for f in $tck1 $indices; do
  if [[ ! -f "$f" ]]; then
    echolor red "File not found: $f"
    isOK=0
  fi
done


if [[ -z "$tck1" || -z "$indices" || -z "$weightsOUT" || -z "$tck1OUT" ]]; then
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
nTracks=$(tckinfo -count "$tck1" | grep "actual count" | awk -F: '{print $2}' | sed 's/[^0-9]//g')
echolor yellow "Number of tracks: $nTracks"

# create a weights file with 1 for indices in the provided file (zero-based), 0 otherwise
# convert zero-based indices to one-based by adding 1 when storing in the array
awk 'NR==FNR{if($1 ~ /^[0-9]+$/) a[$1+1]=1; next} {print (FNR in a) ? 1 : 0}' "$indices" <(seq 1 "$nTracks") > "$weights"



my_do_cmd tckedit -nthreads 0 \
  -tck_weights_in $weights \
  -minweight 0.5 \
  $tck1 \
  $tck1OUT




rm -rf "$tmpDir"