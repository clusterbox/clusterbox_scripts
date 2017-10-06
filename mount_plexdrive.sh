#!/bin/sh
 
USER=cbuser


#Unmount any directories already mounted
echo "mount.sh:  Unmounting all rsync and encrypted directories..."
sudo /bin/fusermount -uz /home/$USER/mount/plexdrive
sudo umount -l /home/$USER/mount/plexdrive

sudo /bin/fusermount -uz /home/$USER/mount/.plexdrive
sudo umount -l /home/$USER/mount/.plexdrive

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
#rm -rf /home/$USER/config/plexdrive/logs
mkdir -p /home/$USER/config/plexdrive/logs

#rm -rf /home/$USER/mount/.plexdrive
mkdir -p /home/$USER/mount/.plexdrive

#rm -rf /home/$USER/mount/plexdrive
mkdir -p /home/$USER/mount/plexdrive

#rm -rf /home/$USER/mount/.local
mkdir -p /home/$USER/mount/.local

#rm -rf /home/$USER/mount/local
mkdir -p /home/$USER/mount/local

#rm -rf /home/$USER/storage
mkdir -p /home/$USER/storage
sudo chown -R $USER:$USER /home/$USER/storage

echo "Wating 3s...."
sleep 3s




## Attempting to mount via plexdrive
echo "mount.sh:  Initializing plexdrive..."
nohup plexdrive mount \
-o allow_other \
-v 3 \
--root-node-id="0B9A6oZoGph2mZHhKdW42TzA1d0U" \
--max-chunks=250 \
--chunk-size="20M" \
--uid=1000 \
--gid=1000 \
/home/$USER/mount/.plexdrive > /home/$USER/config/plexdrive/logs/plexdrive.log &
echo "Wating 3s...."
sleep 3s
 


#Mount encryption over these folders
echo "mount.sh:  Encrypting all hidden directories..."

ENCFS6_CONFIG='/home/'$USER'/config/encfs/encfs.xml' \
nohup encfs \
-o allow_other \
--extpass="cat /home/"$USER"/config/encfs/encfspass" \
-f -v \
/home/$USER/mount/.plexdrive /home/$USER/mount/plexdrive \
2> /home/$USER/config/encfs/logs/plexdrive_crypt.error 1> /home/$USER/config/encfs/logs/plexdrive_crypt.log &


ENCFS6_CONFIG='/home/'$USER'/config/encfs/encfs.xml' \
nohup encfs \
-o allow_other \
--extpass="cat /home/"$USER"/config/encfs/encfspass" \
-f -v \
/home/$USER/mount/.local /home/$USER/mount/local \
2> /home/$USER/config/encfs/logs/local_crypt.error 1> /home/$USER/config/encfs/logs/local_crypt.log &

echo "Wating 3s...."
sleep 3s




#Use union-fs to merge our remote and local directories
echo "mount.sh:  Merging all directories with UnionFS..."
unionfs-fuse \
-o cow,allow_other \
/home/$USER/mount/local=RW:/home/$USER/mount/plexdrive=RO /home/$USER/storage/
echo "Wating 3s...."
sleep 3s



##Adding empty movie tv show directory in local env.  NZBGet uses these.
echo "mount.sh:  Creating all necessary subdirectories in /local..."
mkdir -p /home/$USER/mount/local/tv
mkdir -p /home/$USER/mount/local/movies

sudo chown -R $USER:$USER /home/$USER/mount/local
echo "mount.sh:  Mount.sh Done..."
exit
