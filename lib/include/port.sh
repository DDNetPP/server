#!/bin/bash

port_used=8303

function port_status() {
    port_used="$(get_tw_config sv_port 8303)"
    if netstat --inet -n -a -p 2>/dev/null | grep "$port_used" | grep -qv grep;
    then
        echo "IN USE"
        return
    fi
    echo "NOT IN USE"
}

function check_port() {
    port_used="$(get_tw_config sv_port 8303)"
    if ! [[ $port_used =~ ^[0-9]+$ ]]
    then
        err "Invalid non numeric value for sv_port '$port_used'"
        exit 1
    fi
    log -n "checking port '$port_used' ... "
    if netstat --inet -n -a -p 2>/dev/null | grep "$port_used" | grep -qv grep;
    then
        echo "ERROR"
        err "error port '$port_used' is already in use"
        exit 1
    fi
    echo "OK"
}

