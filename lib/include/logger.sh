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

ERR_LOGFILE=logs/error_log.txt

function is_err_log() {
    if [ "$error_logs" == "0" ]
    then
        return 1;
    elif [ "$error_logs" == "1" ] # 1=no duplicates 2=duplicates
    then
        if [ ! -f "$ERR_LOGFILE" ]
        then
            return 0;
        fi
        last_line="$(tail -n 1 "$ERR_LOGFILE")"
        last_line="${last_line:22}"
        if [ "$last_line" == "$1" ]
        then
            wrn "LOGS ARE EQUAL"
            return 1
        fi
        return 0
    fi
}

function check_cwd() {
    if [ "$cwd" == "" ]
    then
        return;
    fi
    if [ ! -d .git/ ]; then
        cd "$cwd" || { err "log_err: cd '$cwd' failed."; return; }
    elif [ ! -d lib/ ]; then
        cd "$cwd" || { err "log_err: cd '$cwd' failed."; return; }
    elif [ ! -f server.cnf ]; then
        cd "$cwd" || { err "log_err: cd '$cwd' failed."; return; }
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
    if is_err_log "$err"
    then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $err" >> "$ERR_LOGFILE" || err "log_err: failed to write log"
    fi
}

