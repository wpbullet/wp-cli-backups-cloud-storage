#!/usr/bin/env bash
# Source: https://guides.wp-bullet.com
# Author: Mike

#define local path for backups
BACKUPPATH=~/backups

#path to WordPress installations
SITESTORE=/var/www

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

#start the loop
for SITE in ${SITELIST[@]}; do
    #check if there are old backups and delete them
    EXISTS=$(dropbox_uploader list /$SITE | grep -E $DAYSKEPT.*.tar.gz | awk '{print $3}') 
    if [ ! -z $EXISTS ]; then
        dropbox_uploader delete /$SITE/$DAYSKEPT-$SITE.tar.gz /$SITE/
        dropbox_uploader delete /$SITE/$DAYSKEPT-$SITE.sql.gz /$SITE/
    fi
    echo Backing up $SITE
    #enter the WordPress folder
    cd $SITESTORE/$SITE
    if [ ! -e $BACKUPPATH/$SITE ]; then
        mkdir $BACKUPPATH/$SITE
    fi

    #back up the WordPress folder
    tar -czf $BACKUPPATH/$SITE/$DATEFORM-$SITE.tar.gz .

    #back up the WordPress database
    wp db export $BACKUPPATH/$SITE/$DATEFORM-$SITE.sql --allow-root --skip-themes --skip-plugins
    tar -czf $BACKUPPATH/$SITE/$DATEFORM-$SITE.sql.gz $BACKUPPATH/$SITE/$DATEFORM-$SITE.sql
    rm $BACKUPPATH/$SITE/$DATEFORM-$SITE.sql

    #upload packages
    dropbox_uploader upload $BACKUPPATH/$SITE/$DATEFORM-$SITE.tar.gz /$SITE/
    dropbox_uploader upload $BACKUPPATH/$SITE/$DATEFORM-$SITE.sql.gz /$SITE/
done

#if you want to delete all local backups
#rm -rf $BACKUPPATH/*

#delete old backups locally over DAYSKEEP days old
find $BACKUPPATH -type d -mtime +$DAYSKEEP -exec rm -rf {} \;

#Fix permissions
sudo chown -R www-data:www-data $SITESTORE
sudo find $SITESTORE -type f -exec chmod 644 {} +
sudo find $SITESTORE -type d -exec chmod 755 {} +
