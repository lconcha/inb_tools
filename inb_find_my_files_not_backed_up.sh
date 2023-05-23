#!/bin/bash

help() {
echolor bold "
USE: 
`basename $0` <location> <folderName>
"
echo "
Find files that are not being backed up due to incorrect permissions.

<location> can be either:
  'homes' to check your home folder, or
  NAMEOFDISK  corresponding to the name of a /misc subfolder (for example fourier2)
<folderName> is the name of the folder in /misc.
             Normally, this should be your user name, but if the folder has a different name,
             then you can specify it here.

*********************************************
For example, to find files not backed up in /misc/mansfield/lconcha, the command is:
  `basename $0` mansfield lconcha

Example 2, to find files not backed up in /misc/torrey/myOddFolder, the command is:
  `basename $0` torrey myOddFolder

Example 3, to find files not backed up in your HOME (/home/inb/`whoami`):
  `basename $0` homes `whoami`
*********************************************
" 

echolor cyan "
Remember, for a file to be backed up, it should have permissions g=rX,o=rX
"

echo "
LU15 (0N(H4
June, 2019
Rev January, 2020.
INB, UNAM
lconcha@unam.mx

"
}



if [ "$#" -lt 2 ]; then
  echo "[ERROR] - Not enough arguments"
  help
  exit 2
fi



location=$1
u=$2

#u=`whoami`

last_log_file=`ls -rt /misc/sesamo/backup/logs/backup_${location}_* | tail -n 1`

if [ -z $last_log_file ]
then
  echolor red "[ERROR] Cannot find a log file for location $location"
  exit 2
fi

echolor yellow "The last log file for location $location is: $last_log_file"


echolor yellow "Full list of files with improper permissions for backup:"
grep $u $last_log_file

echo  "---------------------------------------------------"
echolor cyan "Directories with one or more files not backed up due to permissions:"

grep $u $last_log_file  | \
  awk -F\" '{print $2}' | \
  awk -F/ '{print $5}'  |
  sort | uniq
echo  "---------------------------------------------------"

echolor yellow "To find specific files within a directory, use the command:"
echolor yellow "  grep $u $last_log_file | grep MYDIRECTORY"

echolor bold "Remember, for a file to be backed up, it should have permissions o=rX"
echolor green "To set the right permissions to a subfolder, the command is:"
echolor green "  chmod -R g+rX,o+rX /path/to/the/subfolder"
echo ""
echo "Always remember to check your backups!"
