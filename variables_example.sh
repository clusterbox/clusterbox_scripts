#!/usr/bin/env bash

#This is an example file.  Move this file to ~/config/variables.sh and fill in appropriately.

USERNAME="$(id -un)" #automatically grab username, dont change
USERID="$(id -u)" #automatically grab user id, don't change
GROUPID="$(id -g)" #automatically grab user group, don't change
KEEPMOUNTS=false #if false, build_clusterbox.sh will always remove and re-create the plexdrive mount
ENCRYPTEDMOVIEFOLDER=IepOejn11g4nP5JHvRa6GShx #encfs encrypted movie folder
ENCRYPTEDTVFOLDER=jCAtPeFmvjtPrlSeYLx5G2kd #encfs encrypted tv folder
RCLONEDEST="gdrive_clusterboxcloud:cb" #Rclone source and folder
PLEXDRIVEROOTNODE="0B9A6oZoGph2mZHhKdW42TzA1d0U" #gdrive folder that plexdrive should mount
DOMAIN="clusterbox.net" #your domain
EMAIL="clusterbox@clusterbox.net" #your email for alerts
TIMEZONE="America/Los Angeles" #your server timezone
