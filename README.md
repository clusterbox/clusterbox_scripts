# Clusterbox Scripts

Clusterbox is a homelab project that uses https://www.linuxserver.io/ Docker containers to bring together Organizr, Obmi, Plex, PlexPy, PlexDrive, Sonarr, Radarr, Nzbget, Transmission, Jackett, NZBHydra, Log.io, Netdata, Portainer, Duplicati, and OwnCloud

Note: Instructions below are for migrating an existing install between servers (No instructions for cold install, yet).

## Step 1: Setup user and install core dependencies on *new* server

//Create a new cbuser on the new server
- `$adduser cbuser`

//Add cbuser to sudo group
- `$usermod -aG sudo cbuser`

//Install git
- `$sudo apt-get install git`

//Install all our dependencies
- `$git clone https://github.com/clusterbox/clusterbox_scripts.git`

//Add our new user to the docker group
- `$sudo usermod -aG docker cbuser`

//Rename the scripts git folder (suggested)
- `$mv clusterbox_scripts/ ~/scripts`

//uncomment user_allow_other from fuse settings
- `$sudo nano /etc/fuse.conf`





## Step 2: Transfer home directory from old server to new server.
//Create zip file we transfer on the new server
- `#sudo zip -r -v cbuser.zip /home/cbuser`

//Rsync zip file to new the server
- `$rsync -avP cbuser.zip cbuser@new_server_ip:/home/cbuser`

//Unpack the zip file on the new server
- `$unzip cbuser.zip -d /home/cbuser`

//Start all our docker containers
- `$./home/cbuser/scripts/build_clusterbox.sh`

//Profit
Point your browser to server IP or configure DNS.



## Possible Hurdles:
- `failed to register layer: devmapper: Error mounting '/dev/mapper/docker-8:2-1056594-844987568e879d45b4e5afbd4c102b6b75ff83d6f3cb8c0f22e083817658cdac' on '/var/lib/docker/devicemapper/mnt/844987568e879d45b4e5afbd4c102b6b75ff83d6f3cb8c0f22e083817658cdac': invalid argument`
You'll need to make sure you're running the generic ubuntu kernel (not custom).  Here are steps to fix on OVH server.
https://github.com/moby/moby/issues/29798#issuecomment-286227359

- I have no idea why, but sometimes after transferring the zip file and decompressing, files area still missing from hidden plexdrive and rclone folders.  Here's how you grab them from the old remote server.
`$rsync -chavzP --stats cbuser@_IP_OLD_SERVER:/home/cbuser/.plexdrive/ /home/cbuser/.plexdrive`
`$rsync -chavzP --stats cbuser@_IP_OLD_SERVER:/home/cbuser/.config/ /home/cbuser/.config`
