#!/bin/bash


swapSize=$1
swapFile=$2

#swapSize can be something like 512m or 8g
#swapFile can be like /mnt/512Mb.swap

# Checar si soy sudo
if [ ! $(id -u) -eq 0 ]; then
	echo "Only sudo can do this"
	exit 2
fi


fallocate -l $swapSize $swapFile

chmod 600 $swapFile

mkswap $swapFile

swapon $swapFile