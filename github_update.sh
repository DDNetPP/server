#!/bin/bash

if [ ! -f srv.txt ]
then
    echo "Error: srv.txt not found."
    echo "make sure you are in the server directory and created a srv.txt with the name of the server."
    exit
fi

srv=$(cat srv.txt)
src_dir=/home/$USER/git/DDNetPP;
srv_dir=$(pwd)

echo "]============== === == ="
figlet $srv
echo "]============== === == ="

echo "This script updates the ddnet++ repo and then moves the binary to the server dir."
echo "repo:   $src_dir/DDNetPP_d"
echo "server: $srv_dir/${srv}_srv_d"
echo "Server keeps running."
echo ""
echo "do you want to update? [y/N]"
read -r -n 1 yn
echo ""

if [[ ! "$yn" =~ [yY] ]]
then
    echo "stopped."
    exit
fi

if [ ! -d $src_dir ]
then
    echo "Path not found: $src_dir"
    echo "make sure to clone the repo to this path"
    echo "$ cd"
    echo "$ mkdir git && cd git"
    echo "$ git clone --recursive https://github.com/DDNetPP/DDNetPP"
    exit
fi

cd $src_dir
git pull;
git submodule update
./bam server_debug;

cd $srv_dir
if [ -f "${srv}_srv_d" ]
then
    echo "[BACKUP] Server";
    mv ${srv}_srv_d ${srv}_srv_d_old;
fi
echo "[UPDATE] binary";
cp $src_dir/DDNetPP_d ${srv}_srv_d;

echo ""
echo "do you also want to update maps? [y/N]"
read -r -n 1 yn
echo ""

if [[ ! "$yn" =~ [yY] ]]
then
    echo "stopped."
    exit
fi

if [ ! -d "$src_dir/maps/" ]
then
    echo "Path not found: $src_dir/maps"
    echo "try updating the submodules"
    echo "$ cd $src_dir"
    echo "$ git submodule update --init --recursive"
    exit
fi

echo "[UPDATE] maps"
mkdir -p maps
cp $src_dir/maps/*.map maps/

