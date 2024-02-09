#!/bin/bash




print_help() {
echo 
echo "
     Delete a file in a remote folder of all nodes in the SGE cluster through ssh.
     Useful to clean up files in /tmp

     Instructions:

     inb_delete_local_file.sh <toDelete>

     <toDelete> can be either a single file or a folder.
     

     If you are using wildcards in <toDelete>, you must use single quotes around <toDelete>
     Example:
     inb_delete_local_file.sh '/tmp/myprocess*'
     

     LU15 (0N(H4
     INB, UNAM
     Feb 2024
     lconcha@unam.mx
     "
}



if [ $# -lt 1 ] 
then
  echo "  ERROR: Need more arguments..."
  print_help
  exit 1
fi



ftodelete=$1





echolor green "Will delete $ftodelete"

whiteList=/home/inb/soporte/inb_cluster_whiteList.txt


errcho(){ >&2 echo $@; }



tmpDir=$(mktemp -d)

cluster_hosts=$(qhost | grep amd64 | awk '{print $1}' | tr '\n'  ' ')

for h in $cluster_hosts
do
  catted=`grep "$h" $whiteList`
  if [ -z "$catted" ]
  then
    echolor cyan "Deleting file(s) in $h"
    ssh  $(whoami)@${h}  "rm -fRv ${ftodelete}"
  else
    errcho "[INFO] Skipping whitelisted node: $h"
  fi
done
