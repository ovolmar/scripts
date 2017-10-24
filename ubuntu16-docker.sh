#!/bin/sh
#DATE:21Sept2017
#Modified: 24OCT2017
#Purpose: Install Docker on Ubuntu 16 Distro
#***************************

# Patch it 
  sudo apt-get install ansible wget -y
  sudo apt-get update -y

# Recommended to allow Docker to use the aufs storage drivers
sudo apt-get install \
  linux-image-extra-$(uname -r) \
  linux-image-extra-virtual -y

#Packages to allow apt to use repo over HTTPS
sudo apt-get install \
  apt-transport-https \
  ca-certificates \
  curl \
  software-properties-common -y


curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository \
  "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) \
  stable"

sudo apt-get install -y docker-ce ; sudo systemctl start docker ; sudo systemctl start docker

sudo usermod -aG docker ${USER} 


#Flushing changes
  sudo systemctl daemon-reload 
# Restart docker and verify changes
  sudo systemctl restart docke
