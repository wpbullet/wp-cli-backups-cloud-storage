#!/usr/bin/env bash
# WP-CLI Back up Script to Amazon S3
# Source: https://guides.wp-bullet.com
# Author: Mike

#define local path for backups
BACKUPPATH=/tmp/backups

#path to WordPress installations
SITESTORE=/var/www

#S3 bucket
S3DIR="s3://bucket-name/backups"

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
    echo Backing up $SITE
    #enter the WordPress folder
    #cd $SITESTORE/$SITE
    if [ ! -e $BACKUPPATH/$SITE ]; then
        mkdir $BACKUPPATH/$SITE
    fi

    #back up the WordPress folder
    tar -czf $BACKUPPATH/$SITE/$DATEFORM-$SITE.tar.gz $SITESTORE/$SITE

    #back up the WordPress database
    wp db export $BACKUPPATH/$SITE/$DATEFORM-$SITE.sql --path=$SITESTORE/$SITE --single-transaction --quick --lock-tables=false --allow-root --skip-themes --skip-plugins
    cat $BACKUPPATH/$SITE/$DATEFORM-$SITE.sql | gzip > $BACKUPPATH/$SITE/$DATEFORM-$SITE.sql.gz
    rm $BACKUPPATH/$SITE/$DATEFORM-$SITE.sql

    #upload packages
    S3DIRUP=$S3DIR/$SITE/$DATE
    aws s3 mv $BACKUPPATH/$SITE/$DATEFORM-$SITE.tar.gz $S3DIRUP
    aws s3 mv $BACKUPPATH/$SITE/$DATEFORM-$SITE.sql.gz $S3DIRUP

    #delete old backups
    S3REM=$S3DIR/$SITE
    aws s3 rm --recursive $S3REM/$DAYSKEPT
done

#if you want to delete all local backups
#rm -rf $BACKUPPATH/*

#delete old backups locally over DAYSKEEP days old
find $BACKUPPATH -type d -mtime +$DAYSKEEP -exec rm -rf {} \;

#Fix permissions
sudo chown -R www-data:www-data $SITESTORE
sudo find $SITESTORE -type f -exec chmod 644 {} +
sudo find $SITESTORE -type d -exec chmod 755 {} +
