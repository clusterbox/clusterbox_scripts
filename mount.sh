#!/bin/sh
 
USER=cbuser

#Unmount any directories already mounted
echo "mount.sh:  Unmounting all rsync and encrypted directories..."
sudo /bin/fusermount -uz /home/$USER/mount/gdrive_clusterbox
sudo umount -l /home/$USER/mount/gdrive_clusterbox

sudo /bin/fusermount -uz /home/$USER/mount/.gdrive_clusterbox
sudo umount -l /home/$USER/mount/.gdrive_clusterbox

#sudo /bin/fusermount -uz /home/$USER/mount/gdrive_unlimited
#sudo umount -l /home/$USER/mount/gdrive_unlimited

#sudo /bin/fusermount -uz /home/$USER/mount/.gdrive_unlimited
#sudo umount -l /home/$USER/mount/.gdrive_unlimited

sudo /bin/fusermount -uz /home/$USER/mount/local
sudo umount -l /home/$USER/mount/local

sudo /bin/fusermount -uz /home/$USER/mount/.local
sudo umount -l /home/$USER/mount/.local

sudo /bin/fusermount -uz /home/$USER/storage
sudo umount -l /home/$USER/storage

echo "Wating 3s...."
sleep 3s

#Create folder structure where necessary
echo "mount.sh:  Creating all necessary folder structures..."
mkdir -p /home/$USER/mount/logs/plexdrive
mkdir -p /home/$USER/mount/.gdrive_clusterbox
mkdir -p /home/$USER/mount/gdrive_clusterbox
#mkdir -p /home/$USER/mount/.gdrive_unlimited
#mkdir -p /home/$USER/mount/gdrive_unlimited
mkdir -p /home/$USER/mount/.local

rm -rf /home/$USER/mount/local
mkdir -p /home/$USER/mount/local

mkdir -p /home/$USER/storage
#sudo chown -R $USER:$USER /storage

echo "Wating 3s...."
sleep 3s

## Attempting to mount via plexdrive
echo "mount.sh:  Initializing plexdrive..."

nohup plexdrive mount \
-o allow_other \
-v 3 \
--root-node-id="0B9A6oZoGph2mZHhKdW42TzA1d0U" \
--chunk-check-threads=4 \
--chunk-load-ahead=4 \
--chunk-load-threads=8 \
--max-chunks=250 \
--fuse-options=allow_other,read_only \
--chunk-size="10M" \
--uid=1000 \
--gid=1000 \
~/mount/.gdrive_clusterbox > /home/$USER/mount/logs/plexdrive/plexdrive.log &


echo "Wating 3s...."
sleep 3s
 
#Mount encryption over these folders
echo "mount.sh:  Encrypting all hidden directories..."
ENCFS6_CONFIG='/home/'$USER'/encfs/encfs.xml' encfs -o allow_other --extpass="cat /home/"$USER"/encfs/encfspass" /home/$USER/mount/.gdrive_clusterbox /home/$USER/mount/gdrive_clusterbox
#ENCFS6_CONFIG='/home/'$USER'/encfs/encfs.xml' encfs -o allow_other --extpass="cat /home/"$USER"/encfs/encfspass" /home/$USER/mount/.gdrive_unlimited /home/$USER/mount/gdrive_unlimited

ENCFS6_CONFIG='/home/'$USER'/encfs/encfs.xml' encfs -o allow_other --extpass="cat /home/"$USER"/encfs/encfspass" /home/$USER/mount/.local /home/$USER/mount/local
 
echo "Wating 3s...."
sleep 3s

#Use union-fs to merge our remote and local directories
echo "mount.sh:  Merging all directories with UnionFS..."
#unionfs-fuse -o cow,allow_other /home/$USER/local=RW:/home/$USER/gdrive_clusterbox=RO:/home/$USER/gdrive_unlimited=RO /storage/
#unionfs-fuse -o cow,allow_other /home/$USER/local=RW:/home/$USER/gdrive_clusterbox=RO /storage/

unionfs-fuse \
-o cow,allow_other,direct_io,sync_read \
/home/$USER/mount/local=RW:/home/$USER/mount/gdrive_clusterbox=RO /home/$USER/storage/


echo "Wating 3s...."
sleep 3s

echo "mount.sh:  Creating all necessary subdirectories in /local..."
mkdir -p /home/$USER/mount/local/tv
mkdir -p /home/$USER/mount/local/movies
mkdir -p /home/$USER/mount/local/anime
#sudo chown -R $USER:$USER /home/$USER/mount/local
 
echo "mount.sh:  Mount.sh Done..."
exit
