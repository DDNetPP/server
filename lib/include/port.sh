#!/bin/bash

port_used=8303

function include_exec() {
    local config="$1"
    while read -r line
    do
        if [[ "$line" =~ exec\ (.*\.cfg) ]]
        then
            include_exec "${BASH_REMATCH[1]}"
        else
            echo "$line"
        fi
    done < "$config"
}

function get_port_used() {
    if [ ! -d lib/ ]
    then
        wrn "could not detect port lib/ directory not found."
        return
    elif [ ! -f autoexec.cfg ]
    then
        # wrn "could not detect port due to missing autoexec.cfg"
        return
    fi
    mkdir -p lib/tmp
    include_exec "autoexec.cfg" > lib/tmp/compiled.cfg
    port="$(grep '^sv_port' lib/tmp/compiled.cfg | tail -n1 | cut -d' ' -f2 | xargs)"
    if [ "$port" == "" ]
    then
        # log "no port found in autoexec.cfg fallback to 8303"
        port_used=8303
    fi
    if ! [[ $port =~ ^[0-9]+$ ]]
    then
        err "Invalid non numeric value for sv_port '$port'"
        exit 1
    fi
    port_used="$port"
    log -n "checking port '$port_used' ... "
}

function check_port() {
    get_port_used
    if netstat --inet -n -a -p 2>/dev/null | grep "$port_used" | grep -qv grep;
    then
        echo ""
        err "error port '$port_used' is already in use"
        exit 1
    fi
    echo "OK"
}

