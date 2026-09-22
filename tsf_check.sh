#!/bin/bash

usage()
{
cat << EOF

Checks a .tsf tractography file for internal consistency: it compares the
"actual count" of streamlines against the "count" reported in the file's
header (as given by tsfinfo). Optionally also checks against a desired count.

USAGE:

$(basename "$0") <tsf_file> [desired_count]

  tsf_file        Path to the .tsf file to check (required).
  desired_count   Expected number of streamlines (optional). If given, an
                  error is reported if it does not match the actual count.

EOF
}

if [ -z "$1" ] || [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
  usage
  exit 1
fi

tsf=$1
desired_count=$2




actual_count=$(tsfinfo -quiet -count "$1" | grep "actual count" | awk -F: '{gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2); print $2}')
reported_count=$(tsfinfo -quiet -count "$1" | grep "    count:" | awk -F: '{gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2); print $2}')

isOK=1
if [ "$actual_count" -ne "$reported_count" ]; then
  echolor orange "[ERROR] Mismatch in counts for $tsf"
  printf "actual count:\t%s\nreported count:\t%s\n" "$actual_count" "$reported_count"
  isOK=0
fi


if [ ! -z $desired_count ]; then
  if [ "$actual_count" -ne "$desired_count" ]; then
    echolor red "[ERROR] Actual count ($actual_count) does not match desired count ($desired_count) for $tsf"
    isOK=0
  fi
fi

if [ $isOK -eq 1 ]; then
  echolor green "[OK] $tsf"
fi
