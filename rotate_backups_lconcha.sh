#!/bin/sh

#this script was taken from here:
# http://www.bryanrite.com/drobo-incremental-rsync-backups/ 

# Modified by Luis Concha to scratch his itch.



# How many backups would you like to keep, each time you run
# the backup script, a new one will be created, so if you want:
# Daily for a week, script goes cron daily and enter 7.
# Hourly for 3 days, script goes cron hourly and enter 72 (24 hours x 3 days)
NUMOFBACKUPS=7
 
# Where are we backing up to?
BACKUPLOC=/mnt/DroboFS/Shares/backup/lconcha
 
# Delete the oldest backup
NUMOFBACKUPS=`expr $NUMOFBACKUPS - 1`
if [ -d $BACKUPLOC/backup.$NUMOFBACKUPS ]; then
        echo "delete backup.$NUMOFBACKUPS"
        rm -Rf $BACKUPLOC/backup.$NUMOFBACKUPS
fi
 
# Move each snapshot
while [ $NUMOFBACKUPS -gt 0 ]
do
        NUMOFBACKUPS=`expr $NUMOFBACKUPS - 1`
        if [ -d $BACKUPLOC/backup.$NUMOFBACKUPS ] ; then
                NEW=`expr $NUMOFBACKUPS + 1`
                mv $BACKUPLOC/backup.$NUMOFBACKUPS $BACKUPLOC/backup.$NEW
                echo "Move backup.$NUMOFBACKUPS to backup.$NEW"
        fi
done