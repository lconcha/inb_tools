#!/bin/bash

verbosity=""
tout=20;# seconds
do_timeout=1
mainserver="hahn"

function help() {
echo "
`basename $0` [Options].

Options:

-V     verbose.
-t     timeout (default $tout seconds)
-T     disable timeout (mutually exclusive with -t)
-h     Print this.

Luis Concha
Nov, 2015
INB, UNAM

"
}


fname_whiteList=/home/inb/soporte/inb_cluster_whiteList.txt

host_group="@allhosts"
hosts=`qhost | grep lx-amd64 | awk '{print $1}'`
#hosts=`qstat -f | grep all.q | sort | awk -F@ '{print $2}' | awk '{print $1}'`
#hosts=$(qconf -sel)
uHosts=$(qstat -f -qs u | grep all.q | sort  | awk '{print $1}' | awk -F@ '{print $2}' | awk -F. '{print $1}' | xargs echo)



declare -i i
i=1
skip=1



for arg in "$@"
do
  case "$arg" in
    -V)
      verbosity="-V"
    ;;
    -t)
      tout=$2
      shift;shift
    ;;
    -T)
      do_timeout=0
    ;;
    -h)
      help
      exit 0
    ;;
    esac
done

if [ $do_timeout -eq 1 ]
then
  to="timeout $tout"
  echo "[INFO] timeout for a host to respond is $tout seconds"
else
  to=""
fi


echo "[INFO] White list: $fname_whiteList"
echo ""

whiteList=`sort $fname_whiteList | tr '\n' ' '`

A="[~~~~~~~~~~~~~~~~~~~~~]";


for h in $hosts
do
  if [[ "$h" == "$mainserver" ]]
  then
    continue
  fi
  hostNameShort=`echo $h | awk -F. '{print $1}'`
  if [[ "${verbosity}" == "-V" ]]
  then
   printf "\n--- %s :\n" $hostNameShort
  else
  B=$hostNameShort
  echo -n "${A:0:-${#B}} $B ] "
   #printf "|%15s: " $hostNameShort
    #printf "$hostNameShort\n"
  fi
    isW=0
    for w in $whiteList
    do
    if [[ "$hostNameShort" = "$w" ]]
    then
      echo "  $hostNameShort is  whitelisted, will not check."
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
      echo "  $hostNameShort is declared as unreachable by SGE, will not check."
      isW=1
      continue
    fi
    if [ $isW -eq 1 ]
    then
	    continue
    fi
  done

  this_ping_OK=1
  # ping -c 1 -q $h > /dev/null && this_ping_OK=1
  # doWarn=1
  # if [ $this_ping_OK -eq 0 ]
  # then
  #   for w in $whiteList
  #   do
  #     if [[ "$hostNameShort" == "$w" ]]
  #     then
  #       echo "  $hostNameShort is down but it is whitelisted"
  #       doWarn=0
  #       break
  #     fi
  #   done
  #   if [ $doWarn -eq 1 ]
  #   then
  #     echo -e "ERROR: $h is DOWN!"
  #   fi
  #   continue
  # fi


  ######################
  if [ $this_ping_OK -eq 1 -a $isW -eq 0 ]
  then
    $to ssh $h /home/inb/soporte/admin_tools/fmrilab_check_NFS.sh $verbosity
  if [[ $? == 124 ]]                                                                             
  then
    echo "[ERROR] $h is taking longer than $tout seconds to respond."
  fi 
  fi
  ######################


done

  echo "
  Note: [.] means it can correctly read a mount point in /misc (one per disk).
        [W] means a whitelisted or disabled mount point (not an error).
        [T] means time out, a host is not responding (maybe it is off?).
  whitelist file is $fname_whiteList

    Whitelisted node(s)/mount(s): $whiteList
    Nodes recognized as down by SGE: $uHosts
  "
