#!/bin/bash

source lib/port.sh

Reset='\033[0m'
Red='\033[0;31m'
Green='\033[0;32m'
Yellow='\033[0;33m'

psaux=$(ps aux)

gitpath=/home/$USER/git

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

function show_latest_logs() {
    check_srvtxt
    logpath="$gitpath/TeeworldsLogs/$srv_name/logs/"
    if [ ! -d $logpath ]
    then
        err "logpath not found '$logpath'"
        exit
    fi
    latest_log=$(ls $logpath | tail -n1)
    latest_log="$logpath$latest_log"
    log "latest log is '$latest_log'"
    less $latest_log
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
        exit
    fi
    if echo $psaux | grep $srv_name | grep -qv grep;
    then
        wrn "process with the same name is running already!"
        echo ""
        log "do you want to start anyways? [y/N]"
        read -r -n 1 yn
        echo ""
        if [[ "$yn" =~ [yY] ]]
        then
            log "ignoring duplicated process..."
            return
        fi
        log "stopping..."
        exit
    fi
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

function check_srvtxt() {
    if [ ! -f srv.txt ]
    then
        err "srv.txt not found."
        err "make sure you are in the server directory and created a srv.txt with the name of the server."
        exit
    fi
    srv_name=$(cat srv.txt)
    srv=bin/$srv_name
}

function check_gitpath() {
    if [ ! -d "$gitpath" ]
    then
        err "git directory not found '$gitpath'"
        echo ""
        log "do you want to create one? [y/N]"
        read -r -n 1 yn
        echo ""
        if [[ "$yn" =~ [yY] ]]
        then
            log "creating git directory..."
            mkdir -p "$gitpath"
        else
            err "no git folder found. stopping..."
            exit
        fi
    fi
}

function check_logdir() {
    if [ -d "$gitpath/TeeworldsLogs" ]
    then
        return # log path found all fine
    fi
    err "log path not found '$gitpath/TeeworldsLogs'"
    log "do you want to create this directory? [y/N]"
    yn=""
    read -r -n 1 yn
    echo ""
    if [[ "$yn" =~ [yY] ]]
    then
        mkdir "$gitpath/TeeworldsLogs"
    else
        log "Are you ChillerDragon?"
        log "Then you can clone https://github.com/ChillerDragon/TeeworldsLogs"
        log "do you want to clone logs repo? [y/N]"
        yn=""
        read -r -n 1 yn
        echo ""
        if [[ "$yn" =~ [yY] ]]
        then
            git clone https://github.com/ChillerDragon/TeeworldsLogs $gitpath/TeeworldsLogs
        fi
    fi
    # make sure the cloning worked
    if [ ! -d "$gitpath/TeeworldsLogs" ]
    then
        err "logs path not found."
        exit
    fi
}

function check_deps() {
    check_srvtxt
    check_gitpath
    check_logdir

    logpath="$gitpath/TeeworldsLogs/$srv_name/logs/"
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
    fi
    # check_port
}

