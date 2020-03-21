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
    if [ "$is_dumps_logpath" == "1" ]
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

function show_latest_logs() {
    logpath="$gitpath_log/$CFG_SRV_NAME/logs/"
    if [ ! -d $logpath ]
    then
        err "logpath not found '$logpath'"
        exit 1
    fi
    latest_log="$(ls "$logpath" | tail -n1)"
    latest_log="$logpath$latest_log"
    if [ ! -f $latest_log ]
    then
        wrn "there are no logfiles yet."
        exit 1
    fi
    num_logs="$(find "$logpath" | wc -l)"
    log "showing latest logfile out of $num_logs logs:"
    echo "$latest_log"
    less "$latest_log"
}

function show_logs() {
    log "do you want to show logs? [y/N]"
    read -r -n 1 yn
    echo ""
    if [[ ! "$yn" =~ [yY] ]]
    then
        return
    fi
    if [ "$logfile" == "" ]
    then
        log "logfile not found."
        log "do you want to show latest logs? [y/N]"
        read -r -n 1 yn
        echo ""
        if [[ "$yn" =~ [yY] ]]
        then
            show_latest_logs
            return
        fi
        exit
    fi
    if [ ! -f "$logfile" ]
    then
        err "logfile not found '$logfile'"
        exit
    fi
    cat "$logfile"
}
