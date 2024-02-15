#!/bin/bash

d=$1

echo "------------------------"
echolor green "First files:"
find $1 -printf "%Tc  |  %p\n" |  head

echo "------------------------"
echolor yellow "Last files:"
find $1 -printf "%Tc  |  %p\n" |  tail
echo "------------------------"