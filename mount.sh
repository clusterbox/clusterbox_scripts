#!/bin/sh
 
USER=cbuser

#Unmount any directories already mounted
echo "mount.sh:  Unmounting all rsync and encrypted directories..."
sudo /bin/fusermount -uz /home/$USER/gdrive_clusterbox
sudo umount -l /home/$USER/gdrive_clusterbox

sudo /bin/fusermount -uz /home/$USER/.gdrive_clusterbox
sudo umount -l /home/$USER/.gdrive_clusterbox

#sudo /bin/fusermount -uz /home/$USER/gdrive_unlimited
#sudo umount -l /home/$USER/gdrive_unlimited

#sudo /bin/fusermount -uz /home/$USER/.gdrive_unlimited
#sudo umount -l /home/$USER/.gdrive_unlimited

sudo /bin/fusermount -uz /home/$USER/local
sudo umount -l /home/$USER/local

sudo /bin/fusermount -uz /home/$USER/.local
sudo umount -l /home/$USER/.local

sudo /bin/fusermount -uz /storage
sudo umount -l /storage

echo "Wating 3s...."
sleep 3s

#Create folder structure where necessary
echo "mount.sh:  Creating all necessary folder structures..."
mkdir -p /home/$USER/.gdrive_clusterbox
mkdir -p /home/$USER/gdrive_clusterbox
#mkdir -p /home/$USER/.gdrive_unlimited
#mkdir -p /home/$USER/gdrive_unlimited
mkdir -p /home/$USER/.local

sudo rm -rf /home/$USER/local
mkdir -p /home/$USER/local

sudo mkdir -p /storage
sudo chown -R $USER:$USER /storage

echo "Wating 3s...."
sleep 3s

#Mount gdrive using rClone
echo "mount.sh:  Initializing plexdrive..."

#rclone mount \
#--read-only \
#--allow-other \
#--acd-templink-threshold 0 \
#--stats 1s \
#--buffer-size 1G \
#--timeout 5s \
#--contimeout 5s \
#--log-file=/home/$USER/rclone_config/gdrive_clusterbox_mount.log \
#-v gdrive_clusterbox:cb /home/$USER/.gdrive_clusterbox &


## Attempting to mount via plexdrive
nohup sudo plexdrive mount \
-o allow_other \
--root-node-id="0B2enl0HmCklJNmh2NnR3UjFnRzA" \
--uid=1000 \
--gid=1000 \
~/.gdrive_clusterbox > /dev/null 2>&1 &


echo "Wating 3s...."
sleep 3s
 
#Mount encryption over these folders
echo "mount.sh:  Encrypting all hidden directories..."
ENCFS6_CONFIG='/home/'$USER'/encfs/encfs.xml' encfs -o allow_other --extpass="cat /home/"$USER"/encfs/encfspass" /home/$USER/.gdrive_clusterbox /home/$USER/gdrive_clusterbox
#ENCFS6_CONFIG='/home/'$USER'/encfs/encfs.xml' encfs -o allow_other --extpass="cat /home/"$USER"/encfs/encfspass" /home/$USER/.gdrive_unlimited /home/$USER/gdrive_unlimited

ENCFS6_CONFIG='/home/'$USER'/encfs/encfs.xml' encfs -o allow_other --extpass="cat /home/"$USER"/encfs/encfspass" /home/$USER/.local /home/$USER/local
 
echo "Wating 3s...."
sleep 3s

#Use union-fs to merge our remote and local directories
echo "mount.sh:  Merging all directories with UnionFS..."
#unionfs-fuse -o cow,allow_other /home/$USER/local=RW:/home/$USER/gdrive_clusterbox=RO:/home/$USER/gdrive_unlimited=RO /storage/
#unionfs-fuse -o cow,allow_other /home/$USER/local=RW:/home/$USER/gdrive_clusterbox=RO /storage/

unionfs-fuse \
-o cow,allow_other,direct_io,sync_read \
/home/$USER/local=RW:/home/$USER/gdrive_clusterbox=RO /storage/


echo "Wating 3s...."
sleep 3s

echo "mount.sh:  Creating all necessary subdirectories in /local..."
mkdir -p /home/$USER/local/tv
mkdir -p /home/$USER/local/movies
mkdir -p /home/$USER/local/anime
sudo chown -R $USER:$USER /home/$USER/local
 
echo "mount.sh:  Mount.sh Done..."
exit
