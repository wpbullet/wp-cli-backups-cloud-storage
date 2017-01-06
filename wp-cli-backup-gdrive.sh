#!/usr/bin/env bash
# Source: https://guides.wp-bullet.com
# Author: Mike

#define local path for backups
BACKUPPATH="/tmp/backups"

#define remote backup path
BACKUPPATHREM="WP-Bullet-Backups"

#path to WordPress installations
SITESTORE="/var/www"

#date prefix
DATEFORM=$(date +"%Y-%m-%d")

#Days to retain
DAYSKEEP=7

#calculate days as filename prefix
DAYSKEPT=$(date +"%Y-%m-%d" -d "-$DAYSKEEP days")

#create array of sites based on folder names
SITELIST=($(ls -lh $SITESTORE | awk '{print $9}'))

#make sure the backup folder exists
mkdir -p $BACKUPPATH

#check remote backup folder exists on gdrive
BACKUPSID=$(gdrive list --no-header | grep $BACKUPPATHREM | grep dir | awk '{ print $1}')
    if [ -z "$BACKUPSID" ]; then
        gdrive mkdir $BACKUPPATHREM
        BACKUPSID=$(gdrive list --no-header | grep $BACKUPPATHREM | grep dir | awk '{ print $1}')
    fi

#start the loop
for SITE in ${SITELIST[@]}; do
    #delete old backup, get folder id and delete if exists
    OLDBACKUP=$(gdrive list --no-header | grep $DAYSKEPT-$SITE | grep dir | awk '{ print $1}')
    if [ ! -z "$OLDBACKUP" ]; then
        gdrive delete $OLDBACKUP
    fi
    
    # create the local backup folder if it doesn't exist
    if [ ! -e $BACKUPPATH/$SITE ]; then
        mkdir $BACKUPPATH/$SITE
    fi

    #entire the WordPress folder
    cd $SITESTORE/$SITE
  
    #back up the WordPress folder
    tar -czf $BACKUPPATH/$SITE/$DATEFORM-$SITE.tar.gz .
    #back up the WordPress database, compress and clean up
    wp db export $BACKUPPATH/$SITE/$DATEFORM-$SITE.sql --allow-root --skip-themes --skip-plugins
    #tar -czf $BACKUPPATH/$SITE/$DATEFORM-$SITE.sql.gz $BACKUPPATH/$SITE/$DATEFORM-$SITE.sql
    cat $BACKUPPATH/$SITE/$DATEFORM-$SITE.sql | gzip > $BACKUPPATH/$SITE/$DATEFORM-$SITE.sql.gz
    rm $BACKUPPATH/$SITE/$DATEFORM-$SITE.sql
    
    #get current folder ID
    SITEFOLDERID=$(gdrive list --no-header | grep $SITE | grep dir | awk '{ print $1}')

    #create folder if doesn't exist
    if [ -z "$SITEFOLDERID" ]; then
        gdrive mkdir --parent $BACKUPSID $SITE
        SITEFOLDERID=$(gdrive list --no-header | grep $SITE | grep dir | awk '{ print $1}')
    fi

    #upload WordPress tar
    gdrive upload --parent $SITEFOLDERID --delete $BACKUPPATH/$SITE/$DATEFORM-$SITE.tar.gz
    #upload wordpress database
    gdrive upload --parent $SITEFOLDERID --delete $BACKUPPATH/$SITE/$DATEFORM-$SITE.sql.gz
done

#Fix permissions
sudo chown -R www-data:www-data $SITESTORE
sudo find $SITESTORE -type f -exec chmod 644 {} +
sudo find $SITESTORE -type d -exec chmod 755 {} +
