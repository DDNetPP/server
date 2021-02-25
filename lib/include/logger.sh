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
    elif [ "$#" == 2 ] && [ "$1" == "-n" ]
    then
        echo -ne "[${Red}error${Reset}] $2"
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
    if [ "$#" == 2 ] && [ "$1" == "-n" ]
    then
      echo -ne "[${Green}+${Reset}] $2"
    else
      echo -e "[${Green}+${Reset}] $1"
    fi
}

ERR_LOGFILE=logs/error_log.txt

function is_err_log() {
    if [ "$CFG_ERROR_LOGS" == "0" ]
    then
        return 1;
    elif [ "$CFG_ERROR_LOGS" == "1" ] # 1=no duplicates 2=duplicates
    then
        if [ ! -f "$ERR_LOGFILE" ]
        then
            return 0;
        fi
        last_line="$(tail -n 1 "$ERR_LOGFILE")"
        last_line="${last_line:22}"
        if [ "$last_line" == "$1" ]
        then
            return 1
        fi
        return 0
    fi
}

function log_err() {
    local err_msg="$1"
    (
        cd "$SCRIPT_ROOT" || exit 1
        if [ ! -d .git/ ]; then
            err "log_err: .git/ not found are you in the server dir?"; return;
        elif [ ! -d lib/ ]; then
            err "log_err: lib/ not found are you in the server dir?"; return;
        elif [ ! -f server.cnf ]; then
            err "log_err: server.cnf not found are you in the server dir?"; return;
        fi
        mkdir -p logs/ || { err "log_err: failed to create logs/ directory"; return; }
        if is_err_log "$err_msg"
        then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] $err_msg" >> "$ERR_LOGFILE" || err "log_err: failed to write log"
        fi
        if [ "$CFG_ERROR_LOGS_API" != "" ]
        then
            log "pwd: $(pwd)"
            log "executing error api cmd:"
            echo "eval \"$CFG_ERROR_LOGS_API\""
            eval "$CFG_ERROR_LOGS_API"
        fi
    )
}

