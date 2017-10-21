#!/usr/bin/env bash

#This is an example file.  Move this file to ~/config/variables.sh and fill in appropriately.

USERNAME="$(id -un)" #automatically grab username, dont change
USERID="$(id -u)" #automatically grab user id, don't change
GROUPID="$(id -g)" #automatically grab user group, don't change
MYSQLPASS="your_mysql_pw" #MySQL password
KEEPMOUNTS=false #if false, build_clusterbox.sh will always remove and re-create the plexdrive mount
ENCRYPTEDMOVIEFOLDER="xxxxxxxxx" #encfs encrypted movie folder
ENCRYPTEDTVFOLDER="yyyyyyyyy" #encfs encrypted tv folder
RCLONEDEST="rclone_source:folder" #Rclone source and folder
PLEXDRIVEROOTNODE="gdrive_folder_id" #gdrive folder that plexdrive should mount
DOMAIN="yourdomain.com" #your domain
EMAIL="email@yourdomain.com" #your email for alerts
TIMEZONE="America/Central" #your server timezone
