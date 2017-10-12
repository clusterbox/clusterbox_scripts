# Clusterbox Scripts

Clusterbox is a homelab project that uses https://www.linuxserver.io/ Docker containers to bring together Organizr, Obmi, Plex, PlexPy, PlexDrive, Sonarr, Radarr, Nzbget, Transmission, Jackett, NZBHydra, Log.io, Netdata, Portainer, Duplicati, and OwnCloud

Note: Instructions below are for migrating an existing install between servers (No instructions for cold install, yet).

## Step 1: Setup user and install core dependencies on *new* server (Ubuntu 16.04)

//Create a user on the new server
- `$adduser your_user`

//Add your_user to the sudo group
- `$usermod -aG sudo your_user`

//Install git
- `$sudo apt-get install git`

//Install all our dependencies
- `$git clone https://github.com/clusterbox/clusterbox_scripts.git`

//Add our new user to the docker group
- `$sudo usermod -aG docker your_user`

//uncomment user_allow_other from fuse settings
- `$sudo nano /etc/fuse.conf`





## Step 2: Transfer home directory from old server to new server.
//Create zip file we transfer on the new server
- `#sudo zip -r -v your_user.zip /home/your_user`

//Rsync zip file to new the server
- `$rsync -avP your_user.zip your_user@new_server_ip:/home/your_user`

//Unpack the zip file on the new server
- `$unzip your_user.zip -d /home/your_user`

//Start all our docker containers
- `$./home/your_user/scripts/build_clusterbox.sh`

//Profit
Point your browser to server IP or configure DNS.



## Possible Hurdles:
- `failed to register layer: devmapper: Error mounting '/dev/mapper/docker-8:2-1056594-844987568e879d45b4e5afbd4c102b6b75ff83d6f3cb8c0f22e083817658cdac' on '/var/lib/docker/devicemapper/mnt/844987568e879d45b4e5afbd4c102b6b75ff83d6f3cb8c0f22e083817658cdac': invalid argument`
You'll need to make sure you're running the generic ubuntu kernel (not custom).  Here are steps to fix on OVH server.
https://github.com/moby/moby/issues/29798#issuecomment-286227359

- I have no idea why, but sometimes after transferring the zip file and decompressing, files area still missing from hidden plexdrive and rclone folders.  Here's how you grab them from the old remote server.
`$rsync -chavzP --stats your_user@_IP_OLD_SERVER:/home/your_user/.plexdrive/ /home/your_user/.plexdrive`
`$rsync -chavzP --stats your_user@_IP_OLD_SERVER:/home/your_user/.config/ /home/your_user/.config`
