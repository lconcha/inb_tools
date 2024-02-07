#!/bin/bash



ftocopy=$1

whiteList=/home/inb/soporte/inb_cluster_whiteList.txt


errcho(){ >&2 echo $@; }



tmpDir=$(mktemp -d)
flocal=${tmpDir}/$(basename $ftocopy)

cluster_hosts=$(qhost | grep amd64 | awk '{print $1}' | tr '\n'  ' ')

for h in $cluster_hosts
do
  catted=`grep "$h" $whiteList`
  if [ -z "$catted" ]
  then
    errcho rsync -av $ftocopy $(whoami)@${h}:$flocal
    ssh $(whoami)@${h} "mkdir $tmpDir"
    rsync -av $ftocopy $(whoami)@${h}:$flocal
  else
    errcho "[INFO] Skipping whitelisted node: $h"
  fi
done

echo $flocal