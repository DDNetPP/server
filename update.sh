#!/bin/bash
srv=fddrace
gitpath=/home/$USER/git/F-DDrace
cwd=$(pwd)

mkdir -p maps || { echo "Error: creating dir maps/"; exit 1; }
mkdir -p logs || { echo "Error: creating dir logs/"; exit 1; }
cd $gitpath
git pull
mkdir -p build || { echo "Error: creating dir build/"; exit 1; }
cd build
cmake .. -DCMAKE_BUILD_TYPE=Debug
make -j6
mv teeworlds_srv $cwd/${srv}_srv
cp data/maps/*.map $cwd/maps

