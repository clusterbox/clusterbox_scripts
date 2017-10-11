#!/bin/sh

#Source instructions for rClone implementation
#https://enztv.wordpress.com/2016/10/19/using-amazon-cloud-drive-with-plex-media-server-and-encrypting-it/

#Source instructions for Dockerizing Clusterbox
#https://zackreed.me/docker-how-and-why-i-use-it/

USER=cbuser
UID=1002
GID-1002
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
    /bin/bash /home/$USER/scripts/mount_plexdrive.sh
fi


echo "Creating docker container folder structures..."
mkdir -p /home/$USER/docker/containers/nzbget/config
mkdir -p /home/$USER/docker/containers/plex/config
mkdir -p /home/$USER/docker/containers/plex/transcode
mkdir -p /home/$USER/docker/containers/plexpy/config
mkdir -p /home/$USER/docker/containers/portainer/config
mkdir -p /home/$USER/docker/containers/radarr/config
mkdir -p /home/$USER/docker/containers/sonarr/config
mkdir -p /home/$USER/docker/containers/organizr/config
mkdir -p /home/$USER/docker/containers/ombi/config
mkdir -p /home/$USER/docker/containers/jackett/config
mkdir -p /home/$USER/docker/containers/jackett/blackhole
mkdir -p /home/$USER/docker/containers/transmission/config
mkdir -p /home/$USER/docker/containers/hydra/config
mkdir -p /home/$USER/docker/containers/hydra/downloads
mkdir -p /home/$USER/docker/containers/rclone.movie/logs
mkdir -p /home/$USER/docker/containers/rclone.tv/logs
mkdir -p /home/$USER/docker/containers/nginx-proxy/certs
mkdir -p /home/$USER/docker/containers/netdata/config
mkdir -p /home/$USER/docker/containers/duplicati/config
mkdir -p /home/$USER/docker/containers/owncloud/apps
mkdir -p /home/$USER/docker/containers/owncloud/config
mkdir -p /home/$USER/docker/containers/owncloud/data
sudo chown -R $USER:$USER /home/$USER/docker

mkdir -p /home/$USER/downloads/nzbget/completed/movies
mkdir -p /home/$USER/downloads/nzbget/completed/tv
mkdir -p /home/$USER/downloads/transmission
sudo chown -R $USER:$USER /home/$USER/downloads

sudo mkdir -p /etc/nginx/certs
sudo touch /etc/nginx/vhost.d
mkdir -p /usr/share/nginx/html

echo "Starting Nginx Proxy Container..."
docker rm -fv nginx-proxy; docker run -d \
--name=nginx-proxy \
-e DEFAULT_HOST=portal.clusterboxcloud.com \
-p 80:80 \
-p 443:443 \
-v /home/$USER/docker/containers/nginx-proxy/certs:/etc/nginx/certs:ro \
-v /etc/nginx/vhost.d \
-v /usr/share/nginx/html \
-v /var/run/docker.sock:/tmp/docker.sock:ro \
--label com.github.jrcs.letsencrypt_nginx_proxy_companion.nginx_proxy \
jwilder/nginx-proxy:alpine


echo "Starting Nginx LetsEncrypt Container..."
docker rm -fv nginx-proxy-lets-encrypt; docker run -d \
--name=nginx-proxy-lets-encrypt \
-v /home/$USER/docker/containers/nginx-proxy/certs:/etc/nginx/certs:rw \
-v /var/run/docker.sock:/var/run/docker.sock:ro \
--volumes-from nginx-proxy \
jrcs/letsencrypt-nginx-proxy-companion



echo "Starting NZBget Container..."
docker rm -fv nzbget; docker run -d \
--name nzbget \
-p 6789:6789 \
-e PUID=$UID -e PGID=$GID \
-v /home/$USER/docker/containers/nzbget/config:/config \
-v /home/$USER/downloads/nzbget:/downloads \
-v /home/$USER/storage:/storage \
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
-e PLEX_UID=$UID -e PLEX_GID=$GID \
-e PUID=$UID -e PGID=$GID \
-e TZ="America/Los Angeles" \
-v /home/$USER/docker/containers/plex/config:/config \
-v /home/$USER/docker/containers/plex/transcode:/transcode \
-v /home/$USER/storage:/data \
-e VIRTUAL_HOST=plex.clusterboxcloud.com \
-e VIRTUAL_PORT=32400 \
plexinc/pms-docker:plexpass


echo "Starting PlexPy Container..."
docker rm -fv plexpy; docker run -d \
--name=plexpy \
--link plex:plex \
--link nzbget:nzbget \
-v /etc/localtime:/etc/localtime:ro \
-v /home/$USER/docker/containers/plexpy/config:/config \
-v /home/$USER/docker/containers/plex/config/Library/Application\ Support/Plex\ Media\ Server/Logs:/logs:ro \
-v /home/$USER/scripts:/custom_scripts \
-e PUID=$UID -e PGID=$GID \
-p 8181:8181 \
linuxserver/plexpy


echo "Installing jsonrpclib-pelix in PlexPy Container"
docker exec -it plexpy pip install jsonrpclib-pelix

echo "Starting Portainer Container..."
docker rm -fv portainer; docker run -d \
--name=portainer \
-p 9000:9000 \
-v /home/$USER/docker/containers/portainer/config:/data \
-v /var/run/docker.sock:/var/run/docker.sock portainer/portainer


echo "Starting Jackett..."
docker rm -fv jackett; docker run -d \
--name=jackett \
-v /home/$USER/docker/containers/jackett/config:/config \
-v /home/$USER/docker/containers/jackett/blackhole:/downloads \
-e PUID=$UID -e PGID=$GID \
-e TZ="America/Los Angeles" \
-v /etc/localtime:/etc/localtime:ro \
-p 9117:9117 \
linuxserver/jackett


echo "Starting Transmission..."
docker rm -fv transmission; docker run -d --cap-add=NET_ADMIN --device=/dev/net/tun -d \
--name=transmission \
--restart="always" \
--dns=8.8.8.8 \
--dns=8.8.8.4 \
-v /home/$USER/downloads/transmission:/data \
-v /etc/localtime:/etc/localtime:ro \
-e PUID=$UID -e PGID=$GID \
--env-file /home/$USER/docker/containers/transmission/config/DockerEnv \
-p 9091:9091 \
haugene/transmission-openvpn


echo "Starting NZB Hydra..."
docker rm -fv hydra; docker run -d \
--name=hydra \
--link nzbget:nzbget \
--link jackett:jackett \
-v /home/$USER/docker/containers/hydra/config:/config \
-v /home/$USER/docker/containers/hydra/downloads:/downloads \
-e PGID=$GID -e PUID=$UID \
-e TZ="America/Los Angeles" \
-p 5075:5075 \
linuxserver/hydra


echo "Starting rclone.movie Container..."
docker rm -fv rclone.movie; docker run -d \
--name=rclone.movie \
-p 8081:8080 \
-v /home/$USER/.config/rclone:/rclone \
-v /home/$USER/mount/local:/local \
-v /home/$USER/mount/local/movies:/local_media \
-v /home/$USER/mount/.local/$ENCRYPTEDMOVIEFOLDER:/source_folder \
-v /home/$USER/docker/containers/rclone.movie/logs:/logs \
-v /home/$USER/mount/plexdrive:/plexdrive \
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
-v /home/$USER/docker/containers/radarr/config:/config \
-v /home/$USER/storage:/storage \
-v /home/$USER/downloads/nzbget:/downloads \
-v /home/$USER/downloads/transmission:/data \
-v /home/$USER/scripts:/scripts \
-e PUID=$UID -e PGID=$GID \
-e TZ="America/Los Angeles" \
-p 7878:7878 \
linuxserver/radarr


echo "Starting rclone.tv Container..."
docker rm -fv rclone.tv; docker run -d \
--name=rclone.tv \
-p 8082:8080 \
-v /home/$USER/.config/rclone:/rclone \
-v /home/$USER/mount/local:/local \
-v /home/$USER/mount/local/tv:/local_media \
-v /home/$USER/mount/.local/$ENCRYPTEDTVFOLDER:/source_folder \
-v /home/$USER/docker/containers/rclone.tv/logs:/logs \
-v /home/$USER/mount/plexdrive:/plexdrive \
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
-p 8989:8989 \
-e PUID=$UID -e PGID=$GID \
-v /etc/localtime:/etc/localtime:ro \
-v /home/$USER/docker/containers/sonarr/config:/config \
-v /home/$USER/storage:/storage \
-v /home/$USER/downloads/nzbget:/downloads \
-v /home/$USER/downloads/transmission:/data \
-v /home/$USER/scripts:/scripts \
linuxserver/sonarr


echo "Starting Ombi..."
docker rm -fv ombi; docker run -d \
--name=ombi \
--link radarr:radarr \
--link sonarr:sonarr \
--link plex:plex \
-v /etc/localtime:/etc/localtime:ro \
-v /home/$USER/docker/containers/ombi/config:/config \
-e PUID=$UID -e PGID=$GID \
-e TZ="America/Los Angeles" \
-p 3579:3579 \
linuxserver/ombi


echo "Starting Watchtower..."
docker rm -fv watchtower; docker run -d \
--name watchtower \
-v /var/run/docker.sock:/var/run/docker.sock \
v2tec/watchtower --interval 60 --cleanup


echo "Starting Log.io..."
docker rm -fv logio; docker run -d \
-p 28778:28778 \
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
-v /home/$USER/downloads:/downloads \
-e "LOGIO_HARVESTER2STREAMNAME=nzbget" \
    -e "LOGIO_HARVESTER2LOGSTREAMS=/downloads/nzbget" \
    -e "LOGIO_HARVESTER2FILEPATTERN=*.log" \
-e "LOGIO_HARVESTER3STREAMNAME=transmission" \
    -e "LOGIO_HARVESTER3LOGSTREAMS=/downloads/transmission" \
    -e "LOGIO_HARVESTER3FILEPATTERN=*.log" \
-v /home/$USER/docker:/docker \
-e "LOGIO_HARVESTER4STREAMNAME=ombi" \
    -e "LOGIO_HARVESTER4LOGSTREAMS=/docker/containers/ombi/config/logs" \
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
-v /home/$USER/config:/config \
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
#-p 3000 \
#-dt krishnasrinivas/wetty


echo "Starting Netdata..."
docker rm -fv netdata; docker run -d --cap-add SYS_PTRACE \
--name=netdata \
-v /proc:/host/proc:ro \
-v /sys:/host/sys:ro \
-v /var/run/docker.sock:/var/run/docker.sock \
-v /home/$USER/docker/containers/netdata/config:/etc/netdata \
-p 19999:19999 \
firehol/netdata:latest

echo "Starting Duplicati..."
docker rm -fv duplicati; docker run -d \
--name=duplicati \
-v /home/$USER/docker/containers/duplicati/config:/config \
-v /home/$USER:/$USER \
-e PUID=$UID -e PGID=$GID \
-p 8200:8200 \
linuxserver/duplicati:latest


echo "Starting OwnCloud..."
docker rm -fv owncloud; docker run -d \
--name=owncloud \
-v /home/$USER/docker/containers/owncloud/apps:/var/www/html/apps \
-v /home/$USER/docker/containers/owncloud/config:/var/www/html/config \
-v /home/$USER/docker/containers/owncloud/data:/var/www/html/data \
-e PUID=$UID -e PGID=$GID \
-p 8201:80 \
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
-v /home/$USER/docker/containers/organizr/config:/config \
-e PUID=$UID -e PGID=$GID \
-e VIRTUAL_HOST=portal.clusterboxcloud.com \
-e LETSENCRYPT_HOST=portal.clusterboxcloud.com \
-e LETSENCRYPT_EMAIL=clusterbox@clusterboxcloud.com \
-e HTTPS_METHOD=noredirect \
-p 29999:29999 \
lsiocommunity/organizr

#--link term:term \

echo "******** ClusterBox Build Complete ********"

exit
