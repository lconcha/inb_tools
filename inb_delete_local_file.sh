#!/bin/bash



ftodelete=$1

whiteList=/home/inb/soporte/inb_cluster_whiteList.txt


errcho(){ >&2 echo $@; }



tmpDir=$(mktemp -d)

cluster_hosts=$(qhost | grep amd64 | awk '{print $1}' | tr '\n'  ' ')

for h in $cluster_hosts
do
  catted=`grep "$h" $whiteList`
  if [ -z "$catted" ]
  then
    echo "Deleting file(s) in $h"
    ssh  $(whoami)@${h}  "rm -fR $ftodelete"
  else
    errcho "[INFO] Skipping whitelisted node: $h"
  fi
done
