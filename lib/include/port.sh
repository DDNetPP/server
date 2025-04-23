#!/bin/bash

port_used=8303

function port_status() {
    port_used="$(get_tw_config sv_port 8303)"
    if netstat --inet -n -a -p 2>/dev/null | grep ":$port_used " | grep -qv grep;
    then
        echo "IN USE"
        return
    fi
    echo "NOT IN USE"
}

function check_bindaddr() {
    addr_used="$(get_tw_config bindaddr empty)"
    if [ "$addr_used" = empty ]
    then
	    return
    fi
    if ! ip a | grep -q "$addr_used"
    then
	    wrn "Warning: your teeworlds config sets bindaddr to '$addr_used'"
	    wrn "         but this address is not listed in the ip a command"
	    wrn "         if you try to bind an invalid ip the server can fail to start"
    fi
}

function check_port() {
    port_used="$(get_tw_config sv_port 8303)"
    if ! [[ $port_used =~ ^[0-9]+$ ]]
    then
        err "Invalid non numeric value for sv_port '$port_used'"
        exit 1
    fi
    log -n "checking port '$port_used' ... "
    if netstat --inet -n -a -p 2>/dev/null | grep ":$port_used " | grep -qv grep;
    then
        echo "ERROR"
        err "error port '$port_used' is already in use"
        exit 1
    fi
    echo "OK"
}

