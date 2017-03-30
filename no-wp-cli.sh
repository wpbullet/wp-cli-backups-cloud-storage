#!/usr/bin/env bash
# Purpose: WordPress staging for Apache
# Source: https://guides.wp-bullet.com
# Adapted
# Author: Mike

# define WordPress path and wp-config.php file
WPPATH="/var/www/domain.com"
WPCONFIG="$WPPATH/wp-config.php"

# extract database host and credentials
DBHOST=$(grep DB_HOST "$WPCONFIG" | awk -F ["\'"] '{ print $4 }')
DBUSER=$(grep DB_USER "$WPCONFIG" | awk -F ["\'"] '{ print $4 }')
DBPASS=$(grep DB_PASSWORD "$WPCONFIG" | awk -F ["\'"] '{ print $4 }')
DBNAME=$(grep DB_NAME "$WPCONFIG" | awk -F ["\'"] '{ print $4 }')

# mysqldump optimized for speed and gzip
mysqldump -h "$DBHOST" -u "$DBUSER" -p"$DBPASS" "$DBNAME" --single-transaction --quick --lock-tables=false | gzip > /tmp/latest.sql.gz
