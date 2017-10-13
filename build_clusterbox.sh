#!/bin/sh

#Source instructions for rClone implementation
#https://enztv.wordpress.com/2016/10/19/using-amazon-cloud-drive-with-plex-media-server-and-encrypting-it/

#Source instructions for Dockerizing Clusterbox
#https://zackreed.me/docker-how-and-why-i-use-it/

USERNAME="$(id -un)"
USERID="$(id -u)"
GROUPID="$(id -g)"
KEEPMOUNTS=false
ENCRYPTEDMOVIEFOLDER=IepOejn11g4nP5JHvRa6GShx
ENCRYPTEDTVFOLDER=jCAtPeFmvjtPrlSeYLx5G2kd
RCLONEDEST="gdrive_clusterboxcloud:cb"


echo "Stopping and removing all docker containers..."
docker rm -f $(docker ps -a -q)


while getopts ':k' opts; do
    case "${opts}" in
        k) KEEPMOUNTS=$OPTARG ;;
    esac
done

if [ "$KEEPMOUNTS" = false ] ; then
    /bin/bash /home/$USERNAME/scripts/mount_plexdrive.sh
fi


echo "Creating docker container folder structures..."
mkdir -p /home/$USERNAME/docker/containers/nzbget/config
mkdir -p /home/$USERNAME/docker/containers/plex/config
mkdir -p /home/$USERNAME/docker/containers/plex/transcode
mkdir -p /home/$USERNAME/docker/containers/plexpy/config
mkdir -p /home/$USERNAME/docker/containers/portainer/config
mkdir -p /home/$USERNAME/docker/containers/radarr/config
mkdir -p /home/$USERNAME/docker/containers/sonarr/config
mkdir -p /home/$USERNAME/docker/containers/organizr/config
mkdir -p /home/$USERNAME/docker/containers/ombi/v2/config
mkdir -p /home/$USERNAME/docker/containers/ombi/v3/config
mkdir -p /home/$USERNAME/docker/containers/jackett/config
mkdir -p /home/$USERNAME/docker/containers/jackett/blackhole
mkdir -p /home/$USERNAME/docker/containers/transmission/config
mkdir -p /home/$USERNAME/docker/containers/hydra/config
mkdir -p /home/$USERNAME/docker/containers/hydra/downloads
mkdir -p /home/$USERNAME/docker/containers/rclone.movie/logs
mkdir -p /home/$USERNAME/docker/containers/rclone.tv/logs
mkdir -p /home/$USERNAME/docker/containers/nginx-proxy/certs
mkdir -p /home/$USERNAME/docker/containers/netdata/config
mkdir -p /home/$USERNAME/docker/containers/duplicati/config
mkdir -p /home/$USERNAME/docker/containers/owncloud/apps
mkdir -p /home/$USERNAME/docker/containers/owncloud/config
mkdir -p /home/$USERNAME/docker/containers/owncloud/data
mkdir -p /home/$USERNAME/docker/containers/owncloud/lib
sudo chown -R $USERNAME:$USERNAME /home/$USERNAME/docker

mkdir -p /home/$USERNAME/downloads/nzbget/completed/movies
mkdir -p /home/$USERNAME/downloads/nzbget/completed/tv
mkdir -p /home/$USERNAME/downloads/transmission
sudo chown -R $USERNAME:$USERNAME /home/$USERNAME/downloads

sudo mkdir -p /etc/nginx/certs
sudo touch /etc/nginx/vhost.d
sudo mkdir -p /usr/share/nginx/html

echo "Starting Nginx Proxy Container..."
docker rm -fv nginx-proxy; docker run -d \
--name=nginx-proxy \
-e DEFAULT_HOST=portal.clusterboxcloud.com \
-p 80:80 \
-p 443:443 \
-v /home/$USERNAME/docker/containers/nginx-proxy/certs:/etc/nginx/certs:ro \
-v /etc/nginx/vhost.d \
-v /usr/share/nginx/html \
-v /var/run/docker.sock:/tmp/docker.sock:ro \
--label com.github.jrcs.letsencrypt_nginx_proxy_companion.nginx_proxy \
jwilder/nginx-proxy:alpine


echo "Starting Nginx LetsEncrypt Container..."
docker rm -fv nginx-proxy-lets-encrypt; docker run -d \
--name=nginx-proxy-lets-encrypt \
-v /home/$USERNAME/docker/containers/nginx-proxy/certs:/etc/nginx/certs:rw \
-v /var/run/docker.sock:/var/run/docker.sock:ro \
--volumes-from nginx-proxy \
jrcs/letsencrypt-nginx-proxy-companion



echo "Starting NZBget Container..."
docker rm -fv nzbget; docker run -d \
--name nzbget \
-p 127.0.0.1:6789:6789 \
-e PUID=$USERID -e PGID=$GROUPID \
-v /home/$USERNAME/docker/containers/nzbget/config:/config \
-v /home/$USERNAME/downloads/nzbget:/downloads \
-v /home/$USERNAME/storage:/storage \
linuxserver/nzbget



echo "Starting Plex Container..."
docker rm -fv plex; docker run -d \
--name plex \
-p 32400:32400 \
-p 32400:32400/udp \
-p 32469:32469 \
-p 32469:32469/udp \
-p 5353:5353/udp \
-p 1900:1900/udp \
-e PLEX_UID=$USERID -e PLEX_GID=$GROUPID \
-e PUID=$USERID -e PGID=$GROUPID \
-e TZ="America/Los Angeles" \
-v /home/$USERNAME/docker/containers/plex/config:/config \
-v /home/$USERNAME/docker/containers/plex/transcode:/transcode \
-v /home/$USERNAME/storage:/data \
-e VIRTUAL_HOST=plex.clusterboxcloud.com \
-e VIRTUAL_PORT=32400 \
plexinc/pms-docker:plexpass


echo "Starting PlexPy Container..."
docker rm -fv plexpy; docker run -d \
--name=plexpy \
--link plex:plex \
--link nzbget:nzbget \
-v /etc/localtime:/etc/localtime:ro \
-v /home/$USERNAME/docker/containers/plexpy/config:/config \
-v /home/$USERNAME/docker/containers/plex/config/Library/Application\ Support/Plex\ Media\ Server/Logs:/logs:ro \
-v /home/$USERNAME/scripts:/custom_scripts \
-e PUID=$USERID -e PGID=$GROUPID \
-p 127.0.0.1:8181:8181 \
linuxserver/plexpy


echo "Installing jsonrpclib-pelix in PlexPy Container"
docker exec -it plexpy pip install jsonrpclib-pelix

echo "Starting Portainer Container..."
docker rm -fv portainer; docker run -d \
--name=portainer \
-p 127.0.0.1:9000:9000 \
-v /home/$USERNAME/docker/containers/portainer/config:/data \
-v /var/run/docker.sock:/var/run/docker.sock portainer/portainer


echo "Starting Jackett..."
docker rm -fv jackett; docker run -d \
--name=jackett \
-v /home/$USERNAME/docker/containers/jackett/config:/config \
-v /home/$USERNAME/docker/containers/jackett/blackhole:/downloads \
-e PUID=$USERID -e PGID=$GROUPID \
-e TZ="America/Los Angeles" \
-v /etc/localtime:/etc/localtime:ro \
-p 127.0.0.1:9117:9117 \
linuxserver/jackett


echo "Starting Transmission..."
docker rm -fv transmission; docker run -d --cap-add=NET_ADMIN --device=/dev/net/tun -d \
--name=transmission \
--restart="always" \
--dns=8.8.8.8 \
--dns=8.8.8.4 \
-v /home/$USERNAME/downloads/transmission:/data \
-v /etc/localtime:/etc/localtime:ro \
-e PUID=$USERID -e PGID=$GROUPID \
--env-file /home/$USERNAME/docker/containers/transmission/config/DockerEnv \
-p 127.0.0.1:9091:9091 \
haugene/transmission-openvpn


echo "Starting NZB Hydra..."
docker rm -fv hydra; docker run -d \
--name=hydra \
--link nzbget:nzbget \
--link jackett:jackett \
-v /home/$USERNAME/docker/containers/hydra/config:/config \
-v /home/$USERNAME/docker/containers/hydra/downloads:/downloads \
-e PGID=$GROUPID -e PUID=$USERID \
-e TZ="America/Los Angeles" \
-p 127.0.0.1:5075:5075 \
linuxserver/hydra


echo "Starting rclone.movie Container..."
docker rm -fv rclone.movie; docker run -d \
--name=rclone.movie \
-p 127.0.0.1:8081:8080 \
-v /home/$USERNAME/.config/rclone:/rclone \
-v /home/$USERNAME/mount/local:/local \
-v /home/$USERNAME/mount/local/movies:/local_media \
-v /home/$USERNAME/mount/.local/$ENCRYPTEDMOVIEFOLDER:/source_folder \
-v /home/$USERNAME/docker/containers/rclone.movie/logs:/logs \
-v /home/$USERNAME/mount/plexdrive:/plexdrive \
-e SYNC_COMMAND="rclone move -v /source_folder/ $RCLONEDEST/$ENCRYPTEDMOVIEFOLDER --size-only" \
that1guy/docker-rclone



echo "Starting Radarr Container..."
docker rm -fv radarr; docker run -d \
--name=radarr \
--link rclone.movie:rclone.movie \
--link transmission:transmission \
--link nzbget:nzbget \
--link hydra:hydra \
--link plex:plex \
-v /home/$USERNAME/docker/containers/radarr/config:/config \
-v /home/$USERNAME/storage:/storage \
-v /home/$USERNAME/downloads/nzbget:/downloads \
-v /home/$USERNAME/downloads/transmission:/data \
-v /home/$USERNAME/scripts:/scripts \
-e PUID=$USERID -e PGID=$GROUPID \
-e TZ="America/Los Angeles" \
-p 127.0.0.1:7878:7878 \
linuxserver/radarr


echo "Starting rclone.tv Container..."
docker rm -fv rclone.tv; docker run -d \
--name=rclone.tv \
-p 127.0.0.1:8082:8080 \
-v /home/$USERNAME/.config/rclone:/rclone \
-v /home/$USERNAME/mount/local:/local \
-v /home/$USERNAME/mount/local/tv:/local_media \
-v /home/$USERNAME/mount/.local/$ENCRYPTEDTVFOLDER:/source_folder \
-v /home/$USERNAME/docker/containers/rclone.tv/logs:/logs \
-v /home/$USERNAME/mount/plexdrive:/plexdrive \
-e SYNC_COMMAND="rclone move -v /source_folder/ $RCLONEDEST/$ENCRYPTEDTVFOLDER --size-only" \
-e CRON_SCHEDULE="* * * * *" \
that1guy/docker-rclone


echo "Starting Sonarr Container..."
docker rm -fv sonarr; docker run -d \
--name=sonarr \
--link rclone.tv:rclone.tv \
--link transmission:transmission \
--link nzbget:nzbget \
--link hydra:hydra \
--link plex:plex \
-p 127.0.0.1:8989:8989 \
-e PUID=$USERID -e PGID=$GROUPID \
-v /etc/localtime:/etc/localtime:ro \
-v /home/$USERNAME/docker/containers/sonarr/config:/config \
-v /home/$USERNAME/storage:/storage \
-v /home/$USERNAME/downloads/nzbget:/downloads \
-v /home/$USERNAME/downloads/transmission:/data \
-v /home/$USERNAME/scripts:/scripts \
linuxserver/sonarr


#echo "Starting Ombi V2..."
#docker rm -fv ombi; docker run -d \
#--name=ombi \
#--link radarr:radarr \
#--link sonarr:sonarr \
#--link plex:plex \
#-v /etc/localtime:/etc/localtime:ro \
#-v /home/$USERNAME/docker/containers/ombi/v2/config:/config \
#-e PUID=$USERID -e PGID=$GROUPID \
#-e TZ="America/Los Angeles" \
#-p 127.0.0.1:3579:3579 \
#linuxserver/ombi




echo "Starting Ombi V3..."
docker rm -fv ombi; docker run -d \
--name=ombi \
--link radarr:radarr \
--link sonarr:sonarr \
--link plex:plex \
-v /etc/localtime:/etc/localtime:ro \
-v /home/$USERNAME/docker/containers/ombi/v3/config:/config \
-e PUID=$USERID -e PGID=$GROUPID \
-e TZ="America/Los Angeles" \
-p 127.0.0.1:3579:3579 \
lsiodev/ombi-preview


echo "Starting Watchtower..."
docker rm -fv watchtower; docker run -d \
--name watchtower \
-v /var/run/docker.sock:/var/run/docker.sock \
v2tec/watchtower --interval 60 --cleanup


echo "Starting Log.io..."
docker rm -fv logio; docker run -d \
-p 127.0.0.1:28778:28778 \
-e "LOGIO_ADMIN_USER=clusterbox" \
-e "LOGIO_ADMIN_PASSWORD=4letterword" \
--name logio \
blacklabelops/logio


echo "Starting Log.io Harvester..."
docker rm -fv harvester; docker run -d \
--restart="always" \
-v /var/lib/docker/containers:/var/lib/docker/containers \
-e "LOGIO_HARVESTER1STREAMNAME=docker" \
    -e "LOGIO_HARVESTER1LOGSTREAMS=/var/lib/docker/containers" \
    -e "LOGIO_HARVESTER1FILEPATTERN=*-json.log" \
-v /home/$USERNAME/downloads:/downloads \
-e "LOGIO_HARVESTER2STREAMNAME=nzbget" \
    -e "LOGIO_HARVESTER2LOGSTREAMS=/downloads/nzbget" \
    -e "LOGIO_HARVESTER2FILEPATTERN=*.log" \
-e "LOGIO_HARVESTER3STREAMNAME=transmission" \
    -e "LOGIO_HARVESTER3LOGSTREAMS=/downloads/transmission" \
    -e "LOGIO_HARVESTER3FILEPATTERN=*.log" \
-v /home/$USERNAME/docker:/docker \
-e "LOGIO_HARVESTER4STREAMNAME=ombi" \
    -e "LOGIO_HARVESTER4LOGSTREAMS=/docker/containers/ombi/v2/config/logs" \
    -e "LOGIO_HARVESTER4FILEPATTERN=*.log" \
-e "LOGIO_HARVESTER5STREAMNAME=organizr" \
    -e "LOGIO_HARVESTER5LOGSTREAMS=/docker/containers/organizr" \
    -e "LOGIO_HARVESTER5FILEPATTERN=*.log" \
-e "LOGIO_HARVESTER6STREAMNAME=plex" \
    -e "LOGIO_HARVESTER6LOGSTREAMS=/docker/containers/plex" \
    -e "LOGIO_HARVESTER6FILEPATTERN=*.log *.txt" \
-e "LOGIO_HARVESTER7STREAMNAME=plexpy" \
    -e "LOGIO_HARVESTER7LOGSTREAMS=/docker/containers/plexpy" \
    -e "LOGIO_HARVESTER7FILEPATTERN=*.log" \
-e "LOGIO_HARVESTER8STREAMNAME=radarr" \
    -e "LOGIO_HARVESTER8LOGSTREAMS=/docker/containers/radarr" \
    -e "LOGIO_HARVESTER8FILEPATTERN=*.log *.txt" \
-e "LOGIO_HARVESTER9STREAMNAME=sonarr" \
    -e "LOGIO_HARVESTER9LOGSTREAMS=/docker/containers/sonarr" \
    -e "LOGIO_HARVESTER9FILEPATTERN=*.log *.txt" \
-e "LOGIO_HARVESTER10STREAMNAME=rclone_movie" \
    -e "LOGIO_HARVESTER10LOGSTREAMS=/docker/containers/rclone.movie" \
    -e "LOGIO_HARVESTER10FILEPATTERN=*.log" \
-e "LOGIO_HARVESTER11STREAMNAME=rclone_tv" \
    -e "LOGIO_HARVESTER11LOGSTREAMS=/docker/containers/rclone.tv" \
    -e "LOGIO_HARVESTER11FILEPATTERN=*.log" \
-e "LOGIO_HARVESTER12STREAMNAME=hydra" \
    -e "LOGIO_HARVESTER12LOGSTREAMS=/docker/containers/hydra" \
    -e "LOGIO_HARVESTER12FILEPATTERN=*.log" \
-v /home/$USERNAME/config:/config \
-e "LOGIO_HARVESTER13STREAMNAME=plexdrive" \
    -e "LOGIO_HARVESTER13LOGSTREAMS=/config/plexdrive/logs" \
    -e "LOGIO_HARVESTER13FILEPATTERN=*.log" \
-e "LOGIO_HARVESTER14STREAMNAME=encfs" \
    -e "LOGIO_HARVESTER14LOGSTREAMS=/config/encfs/logs" \
    -e "LOGIO_HARVESTER14FILEPATTERN=*.log *.error" \
--link logio:logio \
--name harvester \
--user root \
blacklabelops/logio harvester



#echo "Starting Wetty Terminal..."
#docker rm -fv term; docker run -d \
#--name term \
#-p 127.0.0.1:3000:3000 \
#-dt krishnasrinivas/wetty


echo "Starting Netdata..."
docker rm -fv netdata; docker run -d --cap-add SYS_PTRACE \
--name=netdata \
-v /proc:/host/proc:ro \
-v /sys:/host/sys:ro \
-v /var/run/docker.sock:/var/run/docker.sock \
-p 127.0.0.1:1999:1999 \
firehol/netdata:latest

#-v /home/$USERNAME/docker/containers/netdata/config:/etc/netdata \

echo "Starting Duplicati..."
docker rm -fv duplicati; docker run -d \
--name=duplicati \
-v /home/$USERNAME/docker/containers/duplicati/config:/config \
-v /home/$USERNAME:/$USERNAME \
-e PUID=$USERID -e PGID=$GROUPID \
-p 127.0.0.1:8200:8200 \
linuxserver/duplicati:latest


echo "Starting OwnCloud..."
docker rm -fv owncloud; docker run -d \
--name=owncloud \
-v /home/$USERNAME/docker/containers/owncloud/apps:/var/www/html/apps \
-v /home/$USERNAME/docker/containers/owncloud/config:/var/www/html/config \
-v /home/$USERNAME/docker/containers/owncloud/data:/var/www/html/data \
-v /home/$USERNAME/docker/containers/owncloud/lib:/var/www/html/lib \
-e PUID=$USERID -e PGID=$GROUPID \
-e VIRTUAL_HOST=owncloud.clusterboxcloud.com \
-e LETSENCRYPT_HOST=owncloud.clusterboxcloud.com \
-e LETSENCRYPT_EMAIL=clusterbox@clusterboxcloud.com \
-e HTTPS_METHOD=noredirect \
-p 127.0.0.1:8201:80 \
owncloud:latest

echo "Starting Organizr..."
docker rm -fv organizr; docker run -d \
--name=organizr \
--link sonarr:sonarr \
--link radarr:radarr \
--link portainer:portainer \
--link plex:plex \
--link plexpy:plexpy \
--link nzbget:nzbget \
--link ombi:ombi \
--link logio:logio \
--link jackett:jackett \
--link transmission:transmission \
--link netdata:netdata \
--link hydra:hydra \
--link duplicati:duplicati \
--link owncloud:owncloud \
-v /home/$USERNAME/docker/containers/organizr/config:/config \
-e PUID=$USERID -e PGID=$GROUPID \
-e VIRTUAL_HOST=portal.clusterboxcloud.com \
-e LETSENCRYPT_HOST=portal.clusterboxcloud.com \
-e LETSENCRYPT_EMAIL=clusterbox@clusterboxcloud.com \
-e HTTPS_METHOD=noredirect \
-p 127.0.0.1:29999:29999 \
lsiocommunity/organizr

#--link term:term \

echo "******** ClusterBox Build Complete ********"

exit
