#!/bin/bash

Reset='\033[0m'
Red='\033[0;31m'
Green='\033[0;32m'
Yellow='\033[0;33m'

function err() {
  echo -e "[${Red}error${Reset}] $1"
}

function log() {
  echo -e "[${Yellow}*${Reset}] $1"
}

function wrn() {
  echo -e "[${Yellow}!${Reset}] $1"
}

function suc() {
  echo -e "[${Green}+${Reset}] $1"
}

function check_cfg() {
    if [ ! -f autoexec.cfg ]
    then
        wrn "autoexec.cfg not found!"
        echo ""
        log "do you want to create one from template? [y/N]"
        read -r -n 1 yn
        echo ""
        if [[ ! "$yn" =~ [yY] ]]
        then
            log "skipping config..."
            return
        fi
        log "editing template cfg..."
        sed "s/SERVER_NAME/$srv/g" lib/autoexec.txt > autoexec.cfg
        vi autoexec.cfg # TODO: make sure vi is installed
    fi
}

function check_deps() {
    if [ ! -f srv.txt ]
    then
        err "srv.txt not found."
        err "make sure you are in the server directory and created a srv.txt with the name of the server."
        exit
    fi

    if [ ! -d /home/$USER/git/TeeworldsLogs ]
    then
        err "log path not found /home/$USER/git/TeeworldsLogs"
        err "make sure to create this folder"
        exit
    fi

    srv=$(cat srv.txt)
    srv_bin="${srv}_srv_d"
    logpath="/home/$USER/git/TeeworldsLogs/$srv/logs/"

    if [ ! -f "$srv_bin" ]
    then
        err "server binary '$srv_bin' not found!"
        err "make sure the binary and your current path match"
        err "try ./github_update.sh to fetch the new binary"
    exit
    fi

    check_cfg

    if [ ! -d "$logpath" ]
    then
        wrn "logpath '$logpath' not found!"
        echo ""
        log "do you want to create this directory? [y/N]"
        read -r -n 1 yn
        echo ""
        if [[ ! "$yn" =~ [yY] ]]
        then
            log "stopped."
            exit
        fi
        mkdir -p "$logpath" && suc "starting server..."
    fi
}

