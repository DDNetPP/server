#!/bin/bash

if [ ! -f lib/lib.sh ]
then
    echo "Error: lib/lib.sh not found!"
    echo "make sure you are in the root of the server repo"
    exit 1
fi

source lib/lib.sh

cwd=$(pwd)

mkdir -p maps || { echo "Error: creating dir maps/"; exit 1; }
mkdir -p logs || { echo "Error: creating dir logs/"; exit 1; }
mkdir -p bin || { echo "Error: creating dir bin/"; exit 1; }
cd "$gitpath_mod"
git pull
mkdir -p build || { echo "Error: creating dir build/"; exit 1; }
cd build
cmake .. -DCMAKE_BUILD_TYPE=Debug
make -j6 || { err "build failed."; exit 1; }
if [ ! -f "$binary_name" ]
then
    err "Binary not found is your config correct?"
    err "Expected binary name '$binary_name'"
    err "and only found those files:"
    ls
    exit 1
fi
mv "$binary_name" $cwd/bin/${srv_name}_srv_d
cp data/maps/*.map $cwd/maps

cd "$cwd" || exit 1
if [[ -d cfg/ ]] && [[ -d cfg/.git ]]
then
    log "found config directory cfg/"
    log "updating configs ..."
    cd cfg || exit 1
    git pull
fi

