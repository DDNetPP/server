#!/bin/bash

if [ ! -f lib/lib.sh ]
then
    echo "Error: lib/lib.sh not found!"
    echo "make sure you are in the root of the server repo"
    exit 1
fi

source lib/lib.sh

cwd="$(pwd)"

cd "$cwd" || exit 1
if [[ -d cfg/ ]] && [[ -d cfg/.git ]]
then
    log "found config directory cfg/"
    log "updating configs ..."
    cd cfg || exit 1
    git pull
fi
cd "$cwd" || exit 1
if [[ -d votes/ ]] && [[ -d votes/.git ]]
then
    log "found config directory votes/"
    log "updating configs ..."
    cd votes || exit 1
    git pull
fi

