#!/bin/bash
set -e

#echo "----- Installing ruby! -----"
apt update
#SET UP THE REPOSITORY`
apt-get -y install \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
#INSTALL DOCKER CE
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu xenial stable"
apt-get update
apt-get -y install docker-ce
