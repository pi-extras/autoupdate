#!/bin/bash

# Core functions
source api
TOKENSCRIPT="/root/secrets/token.sh"
if [ ! -f $TOKENSCRIPT ]; then
    error "$TOKENSCRIPT couldn't be found. Exiting."
fi
source $TOKENSCRIPT

status "Updating croc."
CROC_API=`curl -s --header "Authorization: token $token" https://api.github.com/repos/schollz/croc/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")'`
CROC_DATAFILE="$HOME/dlfiles-data/croc.txt"
if [ ! -f "$CROC_DATAFILE" ]; then
    status "$CROC_DATAFILE does not exist."
    status "Grabbing the latest release from GitHub."
    echo $CROC_API > $CROC_DATAFILE
fi
croc_CURRENT="$(cat ${croc_DATAFILE})"
if [ "$CROC_CURRENT" != "$CROC_API" ]; then
    status "croc isn't up to date. updating now..."
    curl -s --header "Authorization: token $token" https://api.github.com/repos/schollz/croc/releases/latest \
      | grep browser_download_url \
      | grep 'ARM64.deb"' \
      | cut -d '"' -f 4 \
      | xargs -n 1 curl -L -o croc_${croc_API}_arm64.deb || error "Failed to download croc:arm64!"
    curl -s --header "Authorization: token $token" https://api.github.com/repos/schollz/croc/releases/latest \
      | grep browser_download_url \
      | grep 'ARM.deb"' \
      | cut -d '"' -f 4 \
      | xargs -n 1 curl -L -o croc_${croc_API}_armhf.deb || error "Failed to download croc:armhf!"

    mv croc* $PKGDIR
    echo $CROC_API > $CROC_DATAFILE
    green "croc downloaded successfully."
fi
green "croc is up to date."
