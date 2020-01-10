#!/bin/bash
srv=fddrace
gitpath=/home/$USER/git/F-DDrace
cwd=$(pwd)

cd $gitpath
git pull
mkdir -p build
cd build
cmake .. -DCMAKE_BUILD_TYPE=Debug
make -j6
mv teeworlds_srv $cwd/${srv}_srv
cp data/maps/*.map $cwd/maps

