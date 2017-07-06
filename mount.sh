#!/bin/sh
 
USER=braddavis

#Unmount any directories already mounted
echo "mount.sh:  Unmounting all rsync and encrypted directories..."
sudo /bin/fusermount -uz /home/$USER/gdrive
sudo umount -l /home/$USER/gdrive

sudo /bin/fusermount -uz /home/$USER/.gdrive
sudo umount -l /home/$USER/.gdrive

sudo /bin/fusermount -uz /home/$USER/local
sudo umount -l /home/$USER/local

sudo /bin/fusermount -uz /home/$USER/.local
sudo umount -l /home/$USER/.local

sudo /bin/fusermount -uz /storage
sudo umount -l /storage

echo "Wating 10s..."
sleep 10s

#Create folder structure where necessary
echo "mount.sh:  Creating all necessary folder structures..."
mkdir -p /home/$USER/.gdrive
mkdir -p /home/$USER/gdrive
mkdir -p /home/$USER/.local

sudo rm -rf /home/$USER/local
mkdir -p /home/$USER/local

sudo mkdir -p /storage
sudo chown -R $USER:$USER /storage

echo "Wating 10s..."
sleep 10s

#Mount gdrive using rClone
echo "mount.sh:  Initializing rClone..."
rclone mount gdrive:$USER /home/$USER/.gdrive &

echo "Wating 10s..."
sleep 10s
 
#Mount encryption over these folders
echo "mount.sh:  Encrypting all hidden directories..."
ENCFS6_CONFIG='/home/'$USER'/encfs/encfs.xml' encfs -o allow_other --extpass="cat /home/"$USER"/encfs/encfspass" /home/$USER/.gdrive /home/$USER/gdrive
ENCFS6_CONFIG='/home/'$USER'/encfs/encfs.xml' encfs -o allow_other --extpass="cat /home/"$USER"/encfs/encfspass" /home/$USER/.local /home/$USER/local
 
echo "Wating 10s..."
sleep 10s

#Use union-fs to merge our remote and local directories
echo "mount.sh:  Merging all directories with UnionFS..."
unionfs-fuse -o cow,allow_other /home/$USER/local=RW:/home/$USER/gdrive=RO /storage/

echo "Wating 10s..."
sleep 10s

echo "mount.sh:  Creating all necessary subdirectories in /local..."
mkdir -p /home/$USER/local/tv
mkdir -p /home/$USER/local/movies
mkdir -p /home/$USER/local/anime
 
echo "mount.sh:  Mount.sh Done..."
exit
