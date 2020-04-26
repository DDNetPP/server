#!/bin/bash

if [ ! -f lib/lib.sh ]
then
    echo "Error: lib/lib.sh not found!"
    echo "make sure you are in the root of the server repo"
    exit
fi

source lib/lib.sh

src_dir="$gitpath_src/DDNetPP"
srv_dir="$(pwd)"

yes_flag=0
if [ "$1" == "-y" ] || [ "$1" == "-yes" ]
then
    yes_flag=1
fi

echo "]============== === == ="
figlet "$CFG_SRV_NAME"
echo "]============== === == ="

log "This script updates the ddnet++ repo and then moves the binary to the server dir."
log "repo:   $src_dir/DDNetPP_d"
log "server: $srv_dir/$CFG_BIN"
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

if [ ! -d "$src_dir" ]
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
    git clone --recursive https://github.com/DDNetPP/DDNetPP "$gitpath_src/DDNetPP"
fi

check_bam

cd "$src_dir" || exit 1
git pull;
git submodule update
$bam_bin server_debug;

cd "$srv_dir" || exit 1
mkdir -p bin
if [ -f "$CFG_BIN" ]
then
    log "backup server..."
    mv "$CFG_BIN" ${CFG_BIN}_old;
fi
log "updating server..."
cp "$src_dir/DDNetPP_d" "$CFG_BIN";

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

