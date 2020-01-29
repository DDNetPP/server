#!/bin/bash

psaux=$(ps aux)
gitpath=/home/$USER/git

source lib/include/logger.sh
source lib/include/port.sh
source lib/include/sid.sh
source lib/include/deps.sh
source lib/include/settings.sh
source lib/include/git.sh

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
    logpath="$gitpath_log/$srv_name/logs/"
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
    num_logs="$(ls "$logpath" | wc -l)"
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

function check_running() {
    if [ "$srv_name" == "" ]
    then
        err "server name is empty"
        exit 1
    fi
    if echo $psaux | grep $srv_name | grep -qv grep;
    then
        wrn "process with the same name is running already!"
        echo ""
        log "+-------] running proccesses [--------+"
        ps axo cmd | grep $srv_name | grep -v "grep"
        log "+-------------------------------------+"
        log "do you want to start anyways? [y/N]"
        read -r -n 1 yn
        echo ""
        if ! [[ "$yn" =~ [yY] ]]
        then
            log "stopping..."
            exit
        fi
        log "ignoring duplicated process..."
    fi
    check_port
}

function check_cfg() {
    if [ ! -f autoexec.cfg ]
    then
        wrn "autoexec.cfg not found!"
        echo ""
        log "do you want to create one from template? [y/N]"
        yn=""
        read -r -n 1 yn
        echo ""
        if [[ ! "$yn" =~ [yY] ]]
        then
            log "skipping config..."
            return
        fi
        log "editing template cfg..."
        sed "s/SERVER_NAME/$srv_name/g" lib/autoexec.txt > autoexec.cfg
        vi autoexec.cfg # TODO: make sure vi is installed
    fi
}

function check_directory() {
    local dir="$1"
    if [ ! -d "$dir" ]
    then
        err "directory not found '$dir'"
        echo ""
        log "do you want to create one? [y/N]"
        read -r -n 1 yn
        echo ""
        if [[ "$yn" =~ [yY] ]]
        then
            log "creating '$dir' directory..."
            mkdir -p "$dir"
        else
            err "no '$dir' folder found. stopping..."
            exit 1
        fi
    fi
}

function check_gitpath() {
    if [ "$gitpath_mod" == "" ]
    then
        err "gitpath mod is empty"
        exit 1
    elif [ "$gitpath_log" == "" ]
    then
        err "gitpath log is empty"
        exit 1
    fi
    check_directory "$gitpath_mod"
    check_directory "$gitpath_log"
}

function check_logdir() {
    if [ -d "$gitpath_log" ]
    then
        return # log path found all fine
    fi
    err "log path not found '$gitpath_log'"
    log "do you want to create this directory? [y/N]"
    yn=""
    read -r -n 1 yn
    echo ""
    if [[ "$yn" =~ [yY] ]]
    then
        mkdir "$gitpath_log/"
    fi
    # make sure everything
    if [ ! -d "$gitpath_log/" ]
    then
        err "logs path not found."
        exit 1
    fi
}

function check_deps() {
    check_gitpath
    check_logdir

    logpath="$gitpath_log/$srv_name/logs/"
    srv_bin="${srv}_srv_d"

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
    else
        if [ ! -d "$logpath/.git" ]
        then
            wrn "WARNING: logpath is not a git repository"
        fi
    fi
}

