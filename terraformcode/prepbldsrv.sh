#!/bin/bash
sudo apt-get update
sleep 5
sudo apt install -y openjdk-11-jre-headless
sleep 5
sudo apt install -y maven
sleep 10
sudo apt-get install -y docker*
sleep 10
sudo apt-get update
sudo apt-get install software-properties-common
sudo apt-add-repository --yes ppa:ansible/ansible
sudo apt-get update
sudo apt-get install -y ansible
sudo apt-get install -y python-pip
sleep 5
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
sleep 10
mvn --version > mvn_ver.txt
cat mvn_ver.txt
sleep 10
sudo apt install -y gnupg2 pass
sudo usermod -aG docker $USER
sudo chmod 666 /var/run/docker.sock
sudo usermod -G root $USER