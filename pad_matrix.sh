#!/bin/bash


help() {
  echo "Usage: `basename $0` <input_file> <pad_value> <output_file>"
  echo ""
  echo "Pads each row of a space-separated matrix"
  echo "in <input_file> with <pad_value> to ensure"
  echo "all rows have the same number of columns."
  echo "Writes the padded matrix to <output_file>."
  echo
  echo "pad_value can be any string (e.g., 0, NA, etc.)."
  echo ""
  echo "Example:"
  echo "`basename $0` input.txt 0 output.txt"
  exit 1
}

if [ "$#" -ne 3 ]; then
  echo "Error: Invalid number of arguments."
  echo ""
  help
  exit 2
fi


in_file=$1
pad_value=$2
out_file=$3

awk -v pad="${pad_value}" '{
  if (NF > max) max = NF
  lines[NR] = $0
}
END {
  for (i = 1; i <= NR; i++) {
    split(lines[i], a, " ")
    for (j = 1; j <= max; j++) {
      printf "%s%s", (j <= length(a) ? a[j] : pad), (j < max ? " " : "\n")
    }
  }
}' "$in_file" > $out_file
