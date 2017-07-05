#!/bin/sh

#Source instructions for rClone implementation
#https://enztv.wordpress.com/2016/10/19/using-amazon-cloud-drive-with-plex-media-server-and-encrypting-it/

#Source instructions for Dockerizing Clusterbox
#https://zackreed.me/docker-how-and-why-i-use-it/

USER=braddavis
KEEPMOUNTS=false
ENCRYPTEDMOVIEFOLDER=IepOejn11g4nP5JHvRa6GShx
ENCRYPTEDTVFOLDER=jCAtPeFmvjtPrlSeYLx5G2kd

while getopts ':k' opts; do
    case "${opts}" in
        k) KEEPMOUNTS=$OPTARG ;;
    esac
done

echo "Updating apt-get"
sudo apt-get -qq update

echo "Installing encfs..."
sudo apt-get install -y -qq encfs

echo "Installing unionfs..."
sudo apt-get install -y -qq unionfs-fuse

echo "Installing Docker dependencies..."
sudo apt-get install -y -qq \
    linux-image-extra-$(uname -r) \
    linux-image-extra-virtual

sudo apt-get install -y -qq \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common


echo "Adding Docker GPG key..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo apt-key fingerprint 0EBFCD88

echo "Install Docker..."
sudo add-apt-repository \
   "deb [arch=armhf] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

sudo apt-get install -y docker.io
sudo groupadd docker
sudo usermod -aG docker $USER


if [ "$KEEPMOUNTS" = false ] ; then
    /bin/bash /home/$USER/scripts/mount.sh
fi


echo "Creating docker container folder structures..."
sudo mkdir -p /docker/containers/nzbget/config
sudo mkdir -p /docker/containers/plex/config
sudo mkdir -p /docker/containers/plex/transcode
sudo mkdir -p /docker/containers/plexpy/config
sudo mkdir -p /docker/containers/portainer/config
sudo mkdir -p /docker/containers/radarr/config
sudo mkdir -p /docker/containers/sonarr/config
sudo mkdir -p /docker/containers/muximux/config
sudo mkdir -p /docker/containers/organizr/config
sudo mkdir -p /docker/containers/ombi/config
sudo mkdir -p /docker/downloads/completed/movies
sudo mkdir -p /docker/downloads/completed/tv
sudo chown -R $USER:$USER /docker


echo "Starting Organizr..."
docker rm -fv organizr; docker run -d \
--name=organizr \
--link sonarr:sonarr \
--link radarr:radarr \
--link portainer:portainer \
--link plexpy:plexpy \
--link nzbget:nzbget \
--link ombi:ombi \
-v /docker/containers/organizr/config:/config \
-e PGID=1002 -e PUID=1003  \
-p 80:80 \
lsiocommunity/organizr

echo "Starting NZBget Container..."
docker rm -fv nzbget; docker run -d \
--name nzbget \
-p 6789:6789 \
-e PUID=1002 -e PGID=1003 \
-v /docker/containers/nzbget/config:/config \
-v /docker/downloads:/downloads \
-v /storage:/storage \
linuxserver/nzbget


echo "Starting Plex Container..."
docker rm -fv plex; docker run -d \
--name plex \
--network=host \
-e TZ="America/Los Angeles" \
-v /docker/containers/plex/config:/config \
-v /docker/containers/plex/transcode:/transcode \
-v /storage:/data \
plexinc/pms-docker:plexpass


echo "Starting PlexPy Container..."
docker rm -fv plexpy; docker run -d \
--name=plexpy \
-v /etc/localtime:/etc/localtime:ro \
-v /docker/containers/plexpy/config:/config \
-v /docker/containers/plex/config/Library/Application\040Support/Plex\040Media\040Server/Logs:/logs:ro \
-e PUID=1002 -e PGID=1003 \
-p 8181:8181 \
linuxserver/plexpy


echo "Starting Portainer Container..."
docker rm -fv portainer; docker run -d \
--name=portainer \
-p 9000:9000 \
-v /docker/containers/portainer/config:/data \
-v /var/run/docker.sock:/var/run/docker.sock portainer/portainer


echo "Starting rclone.movie Container..."
docker rm -fv rclone.movie; docker run -d \
--name=rclone.movie \
-p 8081:8080 \
-e SYNC_DESTINATION=gdrive \
-e SYNC_DESTINATION_SUBPATH=braddavis/$ENCRYPTEDMOVIEFOLDER \
-v /home/$USER/.local/$ENCRYPTEDMOVIEFOLDER:/data \
-v /home/braddavis/local/movies:/media \
-v /home/$USER/config/rclone:/config \
-e SYNC_COMMAND="rclone move -v /data/ gdrive:$USER/$ENCRYPTEDMOVIEFOLDER --size-only --config=/config/rclone.conf  --log-file=/app/rclone.log" \
that1guy/docker-rclone


echo "Starting Radarr Container..."
docker rm -fv radarr; docker run -d \
--name=radarr \
--link rclone.movie:rclone.movie \
-v /docker/containers/radarr/config:/config \
-v /storage:/storage \
-v /docker/downloads:/downloads \
-v /home/$USER/scripts:/scripts \
-e PUID=1002 -e PGID=1003 \
-e TZ="America/Los Angeles" \
-p 7878:7878 \
linuxserver/radarr


echo "Starting rclone.tv Container..."
docker rm -fv rclone.tv; docker run -d \
--name=rclone.tv \
-p 8082:8080 \
-e SYNC_DESTINATION=gdrive \
-e SYNC_DESTINATION_SUBPATH=braddavis/$ENCRYPTEDTVFOLDER \
-v /home/$USER/.local/$ENCRYPTEDTVFOLDER:/data \
-v /home/braddavis/local/tv:/media \
-v /home/$USER/config/rclone:/config \
-e SYNC_COMMAND="rclone move -v /data/ gdrive:$USER/$ENCRYPTEDTVFOLDER --size-only --config=/config/rclone.conf  --log-file=/app/rclone.log" \
that1guy/docker-rclone


echo "Starting Sonarr Container..."
docker rm -fv sonarr; docker run -d \
--name=sonarr \
--link rclone.tv:rclone.tv \
-p 8989:8989 \
-e PUID=1002 -e PGID=1003 \
-v /etc/localtime:/etc/localtime:ro \
-v /docker/containers/sonarr/config:/config \
-v /storage:/storage \
-v /docker/downloads:/downloads \
-v /home/$USER/scripts:/scripts \
linuxserver/sonarr


echo "Starting Ombi..."
docker rm -fv ombi; docker run -d \
--name=ombi \
-v /etc/localtime:/etc/localtime:ro \
-v /docker/containers/ombi/config:/config \
-e PGID=1002 -e PUID=1003  \
-e TZ="America/Los Angeles" \
-p 3579:3579 \
linuxserver/ombi


echo "Starting Watchtower..."
docker rm -fv watchtower; docker run -d \
--name watchtower \
-v /var/run/docker.sock:/var/run/docker.sock \
v2tec/watchtower --interval 60 --cleanup


echo "******** ClusterBox Build Complete ********"

exit












#echo "Installing Unzip..."

#sudo apt-get install -y -qq unzip

#echo "Installing rSync..."

#mkdir /home/$USER/tmp
#wget http://downloads.rclone.org/rclone-current-linux-amd64.zip -P /home/$USER/tmp
#cd /home/$USER/tmp
#unzip -o rclone-current-linux-amd64.zip
#cd /home/$USER/tmp/rclone-*-linux-amd64
#sudo cp rclone /usr/bin/
#sudo chown root:root /usr/bin/rclone
#sudo chmod 755 /usr/bin/rclone
#sudo mkdir -p /usr/local/share/man/man1
#sudo cp rclone.1 /usr/local/share/man/man1/
#sudo mandb

#sudo rm /home/$USER/tmp/rclone-current-linux-amd64.zip
#sudo rm -R /home/$USER/tmp

#echo "Installing w3m headless browser...."

#sudo apt-get install -y -qq w3m

#echo "Installing Screen...."

#sudo apt-get install -y -qq screen







#echo "Initializing EncFS Encryption...."

#if [ -f "/home/"$USER"/encfs.xml" ]
#then
#    echo "EncFS encryption already initialized"
#else
#    echo "EncFS first run"
#    encfs --standard /home/$USER/.local /home/$USER/local
#    #Move EncFS to an easier location
#    mv /home/$USER/.local/.encfs6.xml  /home/$USER/encfs.xml

    #Mount encryption over these folders
#    ENCFS6_CONFIG='/home/'$USER'/encfs.xml' encfs --extpass="cat /home/"$USER"/scripts/encfspass" /home/$USER/.gdrive /home/$USER/gdrive
#    ENCFS6_CONFIG='/home/'$USER'/encfs.xml' encfs --extpass="cat /home/"$USER"/scripts/encfspass" /home/$USER/.local /home/$USER/local
#fi


#Use union-fs to merge our remote and local directories
#unionfs-fuse -o cow,allow_other,default_permissions,nonempty /home/$USER/local=RW:/home/$USER/gdrive=RO /storage/
