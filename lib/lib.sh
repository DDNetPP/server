#!/bin/bash

Reset='\033[0m'
Red='\033[0;31m'
Green='\033[0;32m'
Yellow='\033[0;33m'

function check_deps() {
    if [ ! -f srv.txt ]
    then
        echo "Error: srv.txt not found."
        echo "make sure you are in the server directory and created a srv.txt with the name of the server."
        exit
    fi

    if [ ! -d /home/$USER/git/TeeworldsLogs ]
    then
        echo "Error: log path not found /home/$USER/git/TeeworldsLogs"
        echo "make sure to create this folder"
        exit
    fi

    srv=$(cat srv.txt)
    srv_bin="{$srv}_srv_d"
    logpath="/home/$USER/git/TeeworldsLogs/$srv/logs/"

    if [ ! -f "$srv_bin" ]
    then
        echo "Error: server binary '$srv_bin' not found!"
        echo "make sure the binary and your current path match"
        echo "try ./github_update.sh to fetch the new binary"
    exit
    fi

    if [ ! -d "$logpath" ]
    then
        echo "Error: logpath '$logpath' not found!"
        echo ""
        echo "do you want to create this directory? [y/N]"
        read -r -n 1 yn
        echo ""
        if [[ ! "$yn" =~ [yY] ]]
        then
            echo "stopped."
            exit
        fi
        mkdir -p "$logpath"
    fi
}

function err() {
  echo -e "[${Red}error${Reset}] $1"
  exit
}

function log() {
  echo -e "[${Yellow}*${Reset}] $1"
}

function suc() {
  echo -e "[${Green}+${Reset}] $1"
}

