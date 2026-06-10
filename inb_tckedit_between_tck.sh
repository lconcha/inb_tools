#!/bin/bash
source `which my_do_cmd`

help() {
  echo ""
  echo "Usage:"
  echo "`basename $0` tck1 tck2 criteria weightsOUT tck1OUT tck2OUT"
  echo ""
  echolor green "Description:"
  echo "Filter a tractogram and apply the same selection to another tractogram."
  echo "The CRUCIAL aspect is that both tractograms share the same number and organization of streamlines"
  echo "This script is useful to filter streamlines related to cortical surface vertices."
  echo "The idea comes from: https://community.mrtrix.org/t/individual-streamline-index-included-in-tck-file/1104"
  echo ""
  echo "tck1:         Input tck file 1"
  echo "tck2:         Input tck file 2"
  echo "criteria:     Criteria for selecting tracks (e.g., -include, -exclude, etc.)"
  echo "              Wrap your criteria around single quotes to ensure it's treated as a single argument."
  echo "weightsOUT:   Output file for weights of tracks in tck1"
  echo "tck1OUT:      Output tck file for selected tracks from tck1"
  echo "tck2OUT:      Output tck file for selected tracks from tck2"
  echo ""
  echo "LU15 (0N(H4"
  echo "INB UNAM"
  echo "May 2026"
  echo "lconcha@unam.mx"
  exit 1
}


tck1=$1
tck2=$2
criteria="$3"
weightsOUT=$4
tck1OUT=$5
tck2OUT=$6

isOK=1
for f in $tck1 $tck2; do
  if [[ ! -f "$f" ]]; then
    echolor red "File not found: $f"
    isOK=0
  fi
done


if [[ -z "$tck1" || -z "$tck2" || -z "$criteria" || -z "$weightsOUT" || -z "$tck2OUT" ]]; then
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

# create a dummy weights file with all weights set to 1
seq 1 "$nTracks"  > "$weights"


my_do_cmd tckedit -nthreads 0 -force \
  "$criteria" \
  -tck_weights_in $weights \
  -tck_weights_out $weightsOUT \
  $tck1 \
  $tck1OUT

# echolor green weightsOUT:
# cat $weightsOUT

tmpweights="$tmpDir/tmpweights.txt"
awk 'NR==FNR{for(i=1;i<=NF;i++) a[$i]=1; next} {print (FNR in a) ? 1 : 0}' \
    "$weightsOUT" <(seq 1 "$nTracks") > "$tmpweights"

echolor yellow "Number of tracks passing the criteria:"
grep "1" "$tmpweights" | wc -l

my_do_cmd tckedit -nthreads 0 \
  -tck_weights_in $tmpweights \
  -minweight 0.5 \
  $tck2 \
  $tck2OUT




rm -rf "$tmpDir"