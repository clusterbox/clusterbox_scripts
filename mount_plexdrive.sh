#!/bin/sh

source ~/config/variables.sh 

#Unmount any directories already mounted
echo "mount.sh:  Unmounting all rsync and encrypted directories..."
sudo /bin/fusermount -uz /home/$USERNAME/mount/plexdrive
sudo umount -l /home/$USERNAME/mount/plexdrive

sudo /bin/fusermount -uz /home/$USERNAME/mount/.plexdrive
sudo umount -l /home/$USERNAME/mount/.plexdrive

sudo /bin/fusermount -uz /home/$USERNAME/mount/local
sudo umount -l /home/$USERNAME/mount/local

sudo /bin/fusermount -uz /home/$USERNAME/mount/.local
sudo umount -l /home/$USERNAME/mount/.local

sudo /bin/fusermount -uz /home/$USERNAME/storage
sudo umount -l /home/$USERNAME/storage

sudo /bin/fusermount -uz /home/$USERNAME/mount/clusterbox_ocaml
echo "Wating 3s...."
sleep 3s



#Create folder structure where necessary
echo "mount.sh:  Creating all necessary folder structures..."
#rm -rf /home/$USERNAME/config/plexdrive/logs
mkdir -p /home/$USERNAME/config/plexdrive/logs

#rm -rf /home/$USERNAME/mount/.plexdrive
mkdir -p /home/$USERNAME/mount/.plexdrive

#rm -rf /home/$USERNAME/mount/plexdrive
mkdir -p /home/$USERNAME/mount/plexdrive

#rm -rf /home/$USERNAME/mount/.local
mkdir -p /home/$USERNAME/mount/.local

#rm -rf /home/$USERNAME/mount/local
mkdir -p /home/$USERNAME/mount/local

#rm -rf /home/$USERNAME/storage
mkdir -p /home/$USERNAME/storage
sudo chown -R $USERNAME:$USERNAME /home/$USERNAME/storage

echo "Wating 3s...."
sleep 3s




## Attempting to mount via plexdrive
echo "mount.sh:  Initializing plexdrive..."
nohup \
plexdrive mount \
-o allow_other \
-v 3 \
--root-node-id=$PLEXDRIVEROOTNODE \
--uid=$USERID \
--gid=$GROUPID \
/home/$USERNAME/mount/.plexdrive > /home/$USERNAME/config/plexdrive/logs/plexdrive.log &

echo "Wating 3s...."
sleep 3s
 


#Mount encryption over these folders
echo "mount.sh:  Encrypting all hidden directories..."

ENCFS6_CONFIG='/home/'$USERNAME'/config/encfs/encfs.xml' \
encfs \
-o allow_other \
--extpass="cat /home/"$USERNAME"/config/encfs/encfspass" \
/home/$USERNAME/mount/.plexdrive /home/$USERNAME/mount/plexdrive \


ENCFS6_CONFIG='/home/'$USERNAME'/config/encfs/encfs.xml' \
encfs \
-o allow_other \
--extpass="cat /home/"$USERNAME"/config/encfs/encfspass" \
/home/$USERNAME/mount/.local /home/$USERNAME/mount/local \

echo "Wating 3s...."
sleep 3s




#Use union-fs to merge our remote and local directories
echo "mount.sh:  Merging all directories with UnionFS..."
unionfs-fuse \
-o cow,allow_other \
/home/$USERNAME/mount/local=RW:/home/$USERNAME/mount/plexdrive=RO /home/$USERNAME/storage/
echo "Wating 3s...."
sleep 3s



##Adding empty movie tv show directory in local env.  NZBGet uses these.
echo "mount.sh:  Creating all necessary subdirectories in /local..."
mkdir -p /home/$USERNAME/mount/local/tv
mkdir -p /home/$USERNAME/mount/local/movies

sudo chown -R $USERNAME:$USERNAME /home/$USERNAME/mount/local
echo "mount.sh:  Mount.sh Done..."



##Mounting Google Drive as OCAML too.  We use this as a generic dropbox
echo "mounth.sh google-drive-ocamlfuse mounting..."
google-drive-ocamlfuse -label clusterbox_OCAML /home/$USERNAME/mount/clusterbox_ocaml/

exit
