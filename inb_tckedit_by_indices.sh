#!/bin/bash
source `which my_do_cmd`

help() {
  echo "
  Usage:
  `basename $0` tck indices tckOUT
  
  Description:
  Filter a tractogram by a set of streamline indices
  The idea comes from: https://community.mrtrix.org/t/individual-streamline-index-included-in-tck-file/1104
  
  tck:          Input tck file
  indices:      Either a file or a comma-separated list of indices.
                  - If it is a file:  Should contain the indices of streamlines to select
                    Zero-based indices, one per line.
                  - If it is a comma-separated list: Should contain the indices of streamlines to select
                    Zero-based indices, separated by commas (e.g., 0,2,5,10).
                    You can do tricks like 0-10,15,20-25 to specify ranges and individual indices.
  
  tckOUT:       Output tck file for selected tracks from tck

  LU15 (0N(H4
  INB UNAM
  June 2026
  lconcha@unam.mx"
  exit 1
}


tck=$1
indices=$2
tckOUT=$3

if [[ -z "$tck" || -z "$indices" || -z "$tckOUT" ]]; then
  echolor red "Missing required arguments."
  help
  exit 1
fi

if [[ ! -f "$tck" ]]; then
  echolor red "File not found: $tck"
  help
  exit 1
fi

# create a temporary directory (used if we need to write an indices file)
tmpDir=$(mktemp -d)

# If the second argument is not a file, treat it as a comma-separated list
if [[ -f "$indices" ]]; then
  indices_file="$indices"
else
  indices_file="$tmpDir/indices.txt"
  : > "$indices_file"
  # remove spaces, split on commas, expand ranges (e.g., 0-10) and single indices
  IFS=',' read -ra toks <<< "$(echo "$indices" | tr -d ' ' )"
  for tok in "${toks[@]}"; do
    if [[ "$tok" =~ ^([0-9]+)-([0-9]+)$ ]]; then
      start=${BASH_REMATCH[1]}
      end=${BASH_REMATCH[2]}
      if (( start <= end )); then
        for ((i=start;i<=end;i++)); do echo "$i" >> "$indices_file"; done
      else
        for ((i=start;i>=end;i--)); do echo "$i" >> "$indices_file"; done
      fi
    elif [[ "$tok" =~ ^[0-9]+$ ]]; then
      echo "$tok" >> "$indices_file"
    fi
  done
  if [[ ! -s "$indices_file" ]]; then
    echolor red "No valid numeric indices found in provided list: $indices"
    rm -rf "$tmpDir"
    exit 1
  fi
  # sort and remove duplicates
  sort -n -u -o "$indices_file" "$indices_file"
fi


weights="$tmpDir/weights.txt"
nTracks=$(tckinfo -count "$tck" | grep "actual count" | awk -F: '{print $2}' | sed 's/[^0-9]//g')
echolor yellow "Number of tracks in input file: $nTracks"

# create a weights file with 1 for indices in the provided file (zero-based), 0 otherwise
# convert zero-based indices to one-based by adding 1 when storing in the array
awk 'NR==FNR{if($1 ~ /^[0-9]+$/) a[$1+1]=1; next} {print (FNR in a) ? 1 : 0}' "$indices_file" <(seq 1 "$nTracks") > "$weights"


# nthreads MUST BE ZERO or indexing goes to hell.
my_do_cmd tckedit -nthreads 0 \
  -tck_weights_in $weights \
  -minweight 0.5 \
  $tck \
  $tckOUT




rm -rf "$tmpDir"