#!/bin/bash

bam_bin=""

function install_bam() {
    if [ ! -d "$CFG_GIT_ROOT/bam" ]
    then
        err "Path not found: $CFG_GIT_ROOT/bam"
        log "do you want to fetch a fresh source? [y/N]"
        read -r -n 1 yn
        echo ""
        if [[ ! "$yn" =~ [yY] ]]
        then
            err "Bam path not found. Stopping..."
            exit
        fi
        git clone https://github.com/matricks/bam "$CFG_GIT_ROOT/bam"
    fi
    if [ ! -f "$CFG_GIT_ROOT/bam/bam" ]
    then
        wrn "Executable not found: $CFG_GIT_ROOT/bam/bam"
        log "building bam from source..."
        cd "$CFG_GIT_ROOT/bam" || exit 1
        ./make_unix.sh
        r=$?;
        log "build finished with exit code $r"
        if [ $r -ne 0 ]
        then
            err "bam build failed!"
            err "stopping."
            exit
        fi
    fi
    bam_bin="$CFG_GIT_ROOT/bam/bam"
}

function check_bam() {
    command -v bam >/dev/null 2>&1 || {
        install_bam
        return;
    }
    bam_bin=bam # bam in path
}

function install_brew() {
    command -v brew >/dev/null 2>&1 || {
        wrn "to install figlet you need brew"
        log "do you want to install brew? [y/N]"
        read -r -n 1 yn
        echo ""
        if [[ "$yn" =~ [yY] ]]
        then
            /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
        fi
    }
}

function install_figlet() {
    wrn "you need figlet installed to run this script."

    if [[ "$OSTYPE" == "linux-gnu" ]]
    then
        log "do you want to install it now? [y/N]"
        read -r -n 1 yn
        echo ""
        if [[ "$yn" =~ [yY] ]]
        then
            sudo apt install figlet
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]
    then
        log "do you want to install it now? [y/N]"
        read -r -n 1 yn
        echo ""
        if [[ "$yn" =~ [yY] ]]
        then
            install_brew
            brew install figlet
        fi
    fi
    command -v figlet >/dev/null 2>&1 || {
        err "figlet not found."
        exit
    }
}

command -v figlet >/dev/null 2>&1 || {
    install_figlet
}

