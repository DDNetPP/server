#!/bin/bash

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

