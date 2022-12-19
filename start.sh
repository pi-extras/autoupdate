#!/bin/bash

# Start script for Pi Extras autoupdate
# This script should be run from the 'autoupdate' folder on the repo-hosting VM.

# Check for updates
echo "Checking for script updates..."
localhash="$(git rev-parse HEAD)"
latesthash="$(git ls-remote https://github.com/pi-extras/autoupdate.git HEAD | awk '{print $1}')"
if [ "$localhash" != "$latesthash" ] && [ ! -z "$latesthash" ] && [ ! -z "$localhash" ];then
    echo "Out of date, updating now..."
    git clean -fd
    git reset --hard
    git pull https://github.com/pi-extras/autoupdate.git HEAD || error 'Unable to update, please check your internet connection'
else
    echo "Up to date."
fi

# Core functions
source api
TOKENSCRIPT="/root/token.sh"
if [ ! -f $TOKENSCRIPT ]; then
    error "$TOKENSCRIPT couldn't be found. Exiting."
fi
source $TOKENSCRIPT

# create data directory, for storing the version.txt file
mkdir -p $HOME/dlfiles-data

# ensure arm64 and armhf arch are added, needed for apt to download arm software
sudo dpkg --add-architecture arm64
sudo dpkg --add-architecture armhf

# check/download each package
for script in `ls scripts`; do
    chmod +x scripts/$script
    bash scripts/$script || red "Execution of $script failed!"
done

status "Writing packages."
cd /root/pi-extras/debian
for new_pkg in `ls pkgs_incoming`; do
    status $new_pkg
    #reprepro_expect
    /root/secrets/reprepro.exp -- --noguessgpgtty -Vb /root/pi-extras/debian/ includedeb precise /root/pi-extras/debian/pkgs_incoming/$new_pkg
    if [ $? != 0 ]; then
        red "Import of $new_pkg failed!"
    else
        rm -rf pkgs_incoming/$new_pkg
    fi
done
