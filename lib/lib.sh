#!/bin/bash

psaux=$(ps aux)
gitpath=/home/$USER/git

source lib/include/logger.sh
source lib/include/port.sh
source lib/include/sid.sh
source lib/include/deps.sh
source lib/include/settings.sh
source lib/include/git.sh
source lib/include/logs.sh

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

