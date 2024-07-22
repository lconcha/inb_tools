#!/bin/bash

function help() {
echo "
`basename $0` [Options].

Options:

-V     verbose.
-h     Print this.

Luis Concha
Nov, 2015
INB, UNAM

"
}


fname_whiteList=/home/inb/soporte/inb_cluster_whiteList.txt
echo "White list: $fname_whiteList"

host_group="@allhosts"
hosts=`qstat -f | grep all.q | sort | awk -F@ '{print $2}' | awk '{print $1}'`
uHosts=$(qstat -f -qs u | grep all.q | sort  | awk '{print $1}' | awk -F@ '{print $2}' | awk -F. '{print $1}' | xargs echo)



declare -i i
i=1
skip=1


verbosity=""
for arg in "$@"
do
  case "$arg" in
    -V)
      verbosity="-V"
    ;;
    -h)
      help
      exit 0
    ;;
    esac
    i=$[$i+1]
done

whiteList=`sort $fname_whiteList | tr '\n' ' '`


for h in $hosts
do
  hostNameShort=`echo $h | awk -F. '{print $1}'`
  if [[ "${verbosity}" == "-V" ]]
  then
   printf "\n--- %s :\n" $hostNameShort
  else
   printf "%15s: " $hostNameShort
  fi
    isW=0
    for w in $whiteList
    do
    if [[ "$hostNameShort" = "$w" ]]
    then
      echo "  INFO: $hostNameShort is  whitelisted, will not check."
      isW=1
      break
    fi
    done
    if [ $isW -eq 1 ]
    then
	continue
    fi

  for u in $uHosts
  do
   if [[ "$hostNameShort" = "$u" ]]
    then
      echo "  INFO: $hostNameShort is declared as unreachable by SGE, will not check."
      isW=1
      break
    fi
  done

  this_ping_OK=0
  ping -c 1 -q $h > /dev/null && this_ping_OK=1
  doWarn=1
  if [ $this_ping_OK -eq 0 ]
  then
    for w in $whiteList
    do
      if [[ "$hostNameShort" == "$w" ]]
      then
        echo "  INFO: $hostNameShort is down but it is whitelisted"
        doWarn=0
        break
      fi
    done
    if [ $doWarn -eq 1 ]
    then
      echo -e "ERROR: $h is DOWN!"
    fi
    continue
  fi


  ######################
  if [ $this_ping_OK -eq 1 ]
  then
    ssh $h /home/inb/soporte/admin_tools/fmrilab_check_NFS.sh $verbosity
  fi
  ######################


done

  echo "
  Note: [W] means a whitelisted or disabled mount point (not an error).
  whitelist file is $fname_whiteList

    Whitelisted node(s)/mount(s): $whiteList
    Nodes recognized as down by SGE: $uHosts
  "
