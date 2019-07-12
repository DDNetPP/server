#!/bin/bash

if [ ! -f lib/lib.sh ]
then
    echo "Error: lib/lib.sh not found!"
    echo "make sure you are in the root of the server repo"
    exit
fi

source lib/lib.sh

if [ ! -f srv.txt ]
then
    err "Error: srv.txt not found."
    err "make sure you are in the server directory and created a srv.txt with the name of the server."
    exit
fi

srv=$(cat srv.txt)
src_dir=/home/$USER/git/DDNetPP;
srv_dir=$(pwd)

echo "]============== === == ="
figlet $srv
echo "]============== === == ="

log "This script updates the ddnet++ repo and then moves the binary to the server dir."
log "repo:   $src_dir/DDNetPP_d"
log "server: $srv_dir/${srv}_srv_d"
log "Server keeps running."
echo ""
log "do you want to update? [y/N]"
read -r -n 1 yn
echo ""

if [[ ! "$yn" =~ [yY] ]]
then
    log "stopped."
    exit
fi

if [ ! -d $src_dir ]
then
    err "Path not found: $src_dir"
    err "make sure to clone the repo to this path"
    err "$ cd"
    err "$ mkdir git && cd git"
    err "$ git clone --recursive https://github.com/DDNetPP/DDNetPP"
    exit
fi

cd $src_dir
git pull;
git submodule update
./bam server_debug;

cd $srv_dir
if [ -f "${srv}_srv_d" ]
then
    echo "backup server..."
    mv ${srv}_srv_d ${srv}_srv_d_old;
fi
log "updating server..."
cp $src_dir/DDNetPP_d ${srv}_srv_d;

echo ""
log "do you also want to update maps? [y/N]"
read -r -n 1 yn
echo ""

if [[ ! "$yn" =~ [yY] ]]
then
    log "stopped."
    exit
fi

if [ ! -d "$src_dir/maps/" ]
then
    err "Path not found: $src_dir/maps"
    err "try updating the submodules"
    err "$ cd $src_dir"
    err "$ git submodule update --init --recursive"
    exit
fi

log "updating maps..."
mkdir -p maps
cp $src_dir/maps/*.map maps/

