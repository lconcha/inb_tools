#!/bin/bash

user=$1

if [ -z $user ]
then
  user=`whoami`
fi


#host_group="@allhosts"
#hosts=`qconf -shgrp_resolved $host_group | tr ' ' '\n' | sort | tr '\n' ' '`
hosts=`qstat -f | grep all.q | sort | awk -F@ '{print $2}' | awk '{print $1}'`




nJobsTotal=0
nJobsMine=0

printf "  -----------------------------------\n"
printf "  Summary of running jobs \n  user %s in %s\n" $user $host_group
printf "  user\tall\tHost load flags\n"
printf "  -----------------------------------\n"
for h in $hosts
do
        flags6=`qstat -f | grep all.q@${h} | awk '{print $6}' | tr '[:space:]' '-' | sed 's/-//g'`
        flags4=`qstat -f | grep all.q@${h} | awk '{print $4}' | tr '[:space:]' '-' | sed 's/-//g'`
        #if [ -z "$flags" ]
        #then
	#   flags="OK"
        #fi
	nAll=`qstat -u "*"  | grep $h  | wc -l`
	nMine=`qstat -u $user | grep $h  | wc -l`
	printf "  %d\t%d\t%s\t%s\n" $nMine $nAll "${h%.inb.unam.mx} --> ${flags4} ${flags6}"
	nJobsTotal=$(($nJobsTotal + $nAll))
	nJobsMine=$(($nJobsMine + $nMine))
done
printf "  -----------------------------------\n"
printf "  %d\t%d\tTOTAL\n" $nJobsMine $nJobsTotal


my_qw=`qstat   -u $user | grep qw | wc -l `
all_qw=`qstat  -u "*"   | grep qw | wc -l `
my_hqw=`qstat  -u $user -s h | grep qw | wc -l `
all_hqw=`qstat -u "*" -s h   | grep qw | wc -l `
my_Eqw=`qstat  -u $user | grep Eqw | wc -l`
all_Eqw=`qstat -u "*"   | grep Eqw | wc -l`

printf "\n"
printf "  Pending jobs   (%s/all):\t%d/%d\n" $user $(($my_qw + $my_hqw)) $(($all_qw + $all_hqw))
printf "  Errors in jobs (%s/all):\t%d/%d\n" $user $my_Eqw $all_Eqw



if [ $nJobsTotal -gt 0 ]
then
  qusers=`qstat -u "*" | tail -n +2 | awk '{print $4}' | sort | uniq`
  echo ""
  printf "  People using the cluster right now:\n"
  printf "  %s\n" $qusers
else
  echo ""
  echo "  Nobody is using the cluster right now."
fi
