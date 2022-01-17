#!/bin/bash
set -e

sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get autoremove -y

if [ -n ${upgrades} ]; then
    sudo apt-get install unattended-upgrades -y
    sudo dpkg-reconfigure unattended-upgrades

    echo "Unattended upgrades are set!"
fi

echo "Update done..."
