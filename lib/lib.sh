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
source lib/include/dir.sh

function check_warnings() {
    if [ -f failed_sql.sql ]
    then
        wrn "WARNING: file found 'failed_sql.sql'"
        wrn "         add these records manually to the database"
    fi
}

function edit_file() {
    local file=$1
    options=()
    lines=0
    editors="vim vi nano emacs ne cat"
    aEditors=($editors);
    for editor in "${aEditors[@]}"
    do
        options+=("$editor")
        lines=$((lines+1))
    done
    if [ $lines -eq 1 ]
    then
        exit 0
    fi

    PS3='Select a text editor: '
    select opt in "${options[@]}"
    do
        if [[ " ${options[@]} " =~ " ${opt} " ]]
        then
            $opt $file
            return
        else
            echo "invalid option $REPLY"
        fi
    done
}

function install_apt() {
    if [ "$#" != "1" ]
    then
        err "Error: install_dep invalid amount of arguments given"
        err "       expected 1 got $#"
        exit 1
    fi
    local dep="$1"
    if [ -x "$(command -v "$dep")" ]
    then
        return
    fi
    if [ ! -x "$(command -v apt)" ]
    then
        err "Error: package manager apt not found"
        err "       you have to install '$dep' manually"
        exit 1
    fi

    if [ "$UID" == "0" ]
    then
        apt install "$dep" || exit 1
    else
        if [ -x "$(command -v sudo)" ]
        then
            sudo apt install "$dep" || exit 1
        else
            err "Install sudo or switch to root user"
            exit 1
        fi
    fi
    if [ -x "$(command -v "$dep")" ]
    then
        log "Successfully installed dependency '$dep'"
    else
        err "Failed to install dependency '$dep'"
        err "please install it manually"
        exit 1
    fi
}

function install_dep() {
    install_apt "$1"
}

function show_procs() {
    if pgrep "$srv_name"
    then
        wrn "process with the same name is running already!"
        echo ""
        log "+--------] running processes [---------+"
        ps o cmd -p "$(pgrep "$srv_name")" | tail -n1
        log "+--------------------------------------+"
        return 0
    fi
    return 1
}

function check_running() {
    if [ "$srv_name" == "" ]
    then
        err "server name is empty"
        exit 1
    fi
    if show_procs
    then
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
    check_warnings

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
        if [ ! -d "$gitpath_log/.git" ]
        then
            wrn "WARNING: logpath is not a git repository"
        fi
    fi
}

