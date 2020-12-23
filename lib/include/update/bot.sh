#!/bin/bash

# TODO: remove or update this script

if [ ! -f srv.txt ]
then
    echo "Error: srv.txt not found."
    echo "make sure you are in the server directory and created a srv.txt with the name of the server."
    exit
fi
srvlines="$(wc -l srv.txt | cut -d ' ' -f1)"
if [ "$srvlines" != "2" ]
then
    err "srv.txt invalid line amount '$srvlines' != '2'"
    err "make sure first line is server name and second git path"
    exit 1
fi
srv="$(head -n1 srv.txt)"
src_dir=/home/$USER/git/chillerbot-fc;
srv_dir=$(pwd)

echo "]============== === == ="
figlet "chillerbot-FC"
echo "]============== === == ="

echo "This script updates the chillerbot-fc repo and replaces the bot in the server dir."
echo "repo:   $src_dir/chillerbot-FC-0003"
echo "server: $srv_dir/chillerbotFC_${srv}"
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
    echo "$ git clone https://github.com/chillerbot/chillerbot-fc"
    exit
fi

if [ ! -f /home/$USER/git/bam/bam ]
then
    echo "Path not found: /home/$USER/bam/bam"
    echo "make sure to install bam into the /home/$USER/git directory"
    echo "$ cd"
    echo "$ cd git"
    echo "$ git clone https://github.com/matricks/bam"
    echo "$ cd bam"
    echo "$ ./make_unix.sh"
    exit
fi

cd $src_dir
git pull
../bam/bam fakeclient_release

cd $srv_dir
if [ -f chillerbotFC_$srv ]
then
    echo "[BACKUP] binary..."
    mv chillerbotFC_$srv chillerbotFC_${srv}_old
fi
echo "[UPDATE] binary..."
cp $src_dir/chillerbot-FC-0003 chillerbotFC_$srv;

