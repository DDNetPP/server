#!/bin/bash

port_used=8303

function get_port_used() {
    port_used=8303
}

function check_port() {
    get_port_used
    if netstat --inet -n -a -p 2>/dev/null | grep $port_used | grep -qv grep;
    then
        err "error port '$port_used' is already in use"
        exit
    fi
}

