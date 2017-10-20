#!/bin/bash

source ~/config/variables.sh

echo "Adding google-drive-ocamlfuse repository..."
sudo add-apt-repository ppa:alessandro-strada/ppa

echo "Updating apt-get"
sudo apt-get -qq update

echo "Installing google-drive-ocamlfuse"
sudo apt-get install google-drive-ocamlfuse

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
sudo usermod -aG docker $USERNAME

echo "Installing Unzip..."

sudo apt-get install -y -qq unzip

echo "Installing Zip..."

sudo apt-get install -y zip

echo "Installing Git..."

sudo apt-get install -y git

echo "Installing Speedtest..."

sudo apt-get install speedtest-cli

echo "Installing rSync..."

mkdir /home/$USERNAME/tmp
wget http://downloads.rclone.org/rclone-current-linux-amd64.zip -P /home/$USERNAME/tmp
cd /home/$USERNAME/tmp
unzip -o rclone-current-linux-amd64.zip
cd /home/$USERNAME/tmp/rclone-*-linux-amd64
sudo cp rclone /usr/bin/
sudo chown root:root /usr/bin/rclone
sudo chmod 755 /usr/bin/rclone
sudo mkdir -p /usr/local/share/man/man1
sudo cp rclone.1 /usr/local/share/man/man1/
sudo mandb

sudo rm /home/$USERNAME/tmp/rclone-current-linux-amd64.zip
sudo rm -R /home/$USERNAME/tmp

echo "Installing EncFS Encryption...."

sudo apt-get install -y encfs

echo "Installing UnionFS..."

sudo apt-get install -y unionfs-fuse

echo "Installing Plexdrive..."

mkdir /home/$USERNAME/tmp
wget https://github.com/dweidenfeld/plexdrive/releases/download/5.0.0/plexdrive-linux-amd64 -P /home/$USERNAME/tmp
cd /home/$USERNAME/tmp
sudo mv plexdrive-linux-amd64 plexdrive
sudo mv plexdrive /usr/bin
sudo chown root:root /usr/bin/plexdrive
sudo chmod 755 /usr/bin/plexdrive

sudo rm -R /home/$USERNAME/tmp

echo "Installing nload"
sudo apt-get install nload

echo "Installing nethogs..."
sudo apt-get install nethogs

echo "Installing Nano..."
sudo apt-get install nano

exit
