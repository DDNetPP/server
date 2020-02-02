#!/bin/bash

Reset='\033[0m'
Red='\033[0;31m'
Green='\033[0;32m'
Yellow='\033[0;33m'

function err() {
    if [ "$#" == 2 ] && [ "$1" == "--log" ]
    then
        log_err "$2"
        echo -e "[${Red}error${Reset}] $2"
    else
        echo -e "[${Red}error${Reset}] $1"
    fi
}

function log() {
    if [ "$#" == 2 ] && [ "$1" == "-n" ]
    then
      echo -ne "[${Yellow}*${Reset}] $2"
    else
      echo -e "[${Yellow}*${Reset}] $1"
    fi
}

function wrn() {
      echo -e "[${Yellow}!${Reset}] $1"
}

function suc() {
      echo -e "[${Green}+${Reset}] $1"
}

function check_cwd() {
    if [ "$cwd" == "" ]
    then
        return;
    fi
    if [ ! -d .git/ ]; then
        cd "$cwd"
    elif [ ! -d lib/ ]; then
        cd "$cwd"
    elif [ ! -f server.cnf ]; then
        cd "$cwd"
    fi
}

function log_err() {
    local err="$1"
    check_cwd
    if [ ! -d .git/ ]; then
        err "log_err: .git/ not found are you in the server dir?"; return;
    elif [ ! -d lib/ ]; then
        err "log_err: lib/ not found are you in the server dir?"; return;
    elif [ ! -f server.cnf ]; then
        err "log_err: server.cnf not found are you in the server dir?"; return;
    fi
    mkdir -p logs/ || { err "log_err: failed to create logs/ directory"; return; }
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $err" >> logs/error_log.txt || err "log_err: failed to write log"
}

