#!/bin/bash

if [ ! -f lib/lib.sh ]
then
    echo "Error: lib/lib.sh not found!"
    echo "make sure you are in the root of the server repo"
    exit
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
make -j6
mv teeworlds_srv $cwd/bin/${srv_name}_srv_d
cp data/maps/*.map $cwd/maps

