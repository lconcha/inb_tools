#!/bin/bash

tsf=$1
desired_count=$2

actual_count=$(tsfinfo -quiet -count "$1" | grep "actual count" | awk -F: '{gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2); print $2}')
reported_count=$(tsfinfo -quiet -count "$1" | grep "    count:" | awk -F: '{gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2); print $2}')

if [ "$actual_count" -ne "$reported_count" ]; then
  echolor orange "[ERROR] Mismatch in counts for $tsf"
  printf "actual count:\t%s\nreported count:\t%s\n" "$actual_count" "$reported_count"
fi


if [ ! -z $desired_count ]; then
  if [ "$actual_count" -ne "$desired_count" ]; then
    echolor red "[ERROR] Actual count ($actual_count) does not match desired count ($desired_count) for $tsf"
  fi
fi
