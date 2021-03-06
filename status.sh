#!/bin/bash

if [ ! -f lib/lib.sh ]
then
    echo "Error: lib/lib.sh not found!"
    echo "make sure you are in the root of the server repo"
    exit
fi

source lib/lib.sh

check_warnings

if pgrep -f "$server_id" > /dev/null
then
    suc -n "server is up and running '$server_id'"
    if proc_in_screen "$server_id" >/dev/null
    then
        tput bold
        echo " (SCREEN)"
        tput sgr0
    else
        echo ""
    fi
    check_logpath
    exit
else
    wrn "no server with this id found '$server_id'"
fi

show_procs
log "port: $(get_tw_config sv_port 8303) ($(port_status))"

