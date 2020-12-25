#!/bin/bash

function check_logpath() {
    local logpath
    if [ ! -d lib/ ] || [ ! -f lib/tmp/logpath.txt ]
    then
        return
    fi
    logpath="$(cat lib/tmp/logpath.txt)"
    if [ "$logpath" == "" ]
    then
        return
    fi
    if [ ! -f "$logpath" ] && [ ! -f "$logpath.txt" ]
    then
        wrn "WARNING: did not find logfile:"
        echo "$logpath"
    fi
}

function cache_logpath() {
    local logpath="$1"
    if [ ! -d lib/ ]
    then
        return
    fi
    mkdir -p lib/tmp
    if [ "$IS_DUMPS_LOGPATH" == "1" ]
    then
        if [ "$HOME" == "" ]
        then
            err "Error: \$HOME is not set"
            exit 1
        fi
        dumpsdir="^$HOME/.teeworlds/dumps/"
        if [[ ! "$logpath" =~ $dumpsdir ]]
        then
            logpath="$HOME/.teeworlds/dumps/$logpath"
        fi
    fi
    echo "$logpath" > lib/tmp/logpath.txt
}

function show_latest_log() {
    # usage: show_latest_log [-f] [path]
    # -f to follow
    # path to use custom log dir instead of cfg gitpath
    logpath="$LOGS_PATH_FULL"
    if [ "$2" != "" ]
    then
        logpath="./logs/$2"
    fi
    if [ ! -d "$logpath" ]
    then
        err "log path not found '$logpath'"
        exit 1
    fi
    latest_log="$(find "$logpath" | sort | tail -n1)"
    if [ ! -f "$latest_log" ]
    then
        wrn "there are no logfiles yet."
        exit 1
    fi
    num_logs="$(find "$logpath" | wc -l)"
    num_logs="$((num_logs - 1))"
    log "showing latest logfile out of $num_logs logs:"
    echo "$latest_log"
    if [ "$1" == "-f" ]
    then
        tail -f "$latest_log"
    else
        less "$latest_log"
    fi
}

function show_log_file() {
    local logfile="$1"
    log "logfile: $logfile"
    log "do you want to show the logfile? [y/N]"
    read -r -n 1 yn
    echo ""
    if [[ ! "$yn" =~ [yY] ]]
    then
        return
    fi
    if [ ! -f "$logfile" ] || [ "$logfile" == "" ]
    then
        err "logfile not found '$logfile'"
        exit 1
    fi
    cat "$logfile"
}

