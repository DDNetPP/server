#!/bin/bash

if [ ! -f lib/lib.sh ]
then
    echo "Error: lib/lib.sh not found!"
    echo "make sure you are in the root of the server repo"
    exit
fi

source lib/lib.sh

check_srvtxt
src_dir=$gitpath/DDNetPP;
srv_dir=$(pwd)

yes_flag=0
if [ "$1" == "-y" ] || [ "$1" == "-yes" ]
then
    yes_flag=1
fi

echo "]============== === == ="
figlet $srv_name
echo "]============== === == ="

log "This script updates the ddnet++ repo and then moves the binary to the server dir."
log "repo:   $src_dir/DDNetPP_d"
log "server: $srv_dir/${srv}_srv_d"
log "Server keeps running."
echo ""
log "do you want to update? [y/N]"
yn=Y
if [ $yes_flag -eq 0 ]
then
    read -r -n 1 yn
fi
echo ""

if [[ ! "$yn" =~ [yY] ]]
then
    log "stopped."
    exit
fi

if [ ! -d $src_dir ]
then
    err "Path not found: $src_dir"
    log "do you want to fetch a fresh source? [y/N]"
    yn=Y
    if [ $yes_flag -eq 0 ]
    then
        read -r -n 1 yn
    fi
    echo ""
    if [[ ! "$yn" =~ [yY] ]]
    then
        err "Source path not found. Stopping..."
        exit
    fi
    git clone --recursive https://github.com/DDNetPP/DDNetPP $gitpath/DDNetPP
fi

check_bam

cd $src_dir
git pull;
git submodule update
$bam_bin server_debug;

cd $srv_dir
mkdir -p bin
if [ -f "${srv}_srv_d" ]
then
    log "backup server..."
    mv ${srv}_srv_d ${srv}_srv_d_old;
fi
log "updating server..."
cp $src_dir/DDNetPP_d ${srv}_srv_d;

echo ""
log "do you also want to update maps? [y/N]"
yn=Y
if [ $yes_flag -eq 0 ]
then
    read -r -n 1 yn
fi
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

