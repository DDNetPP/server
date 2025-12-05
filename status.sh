#!/bin/bash

if [ ! -f lib/lib.sh ]
then
    echo "Error: lib/lib.sh not found!"
    echo "make sure you are in the root of the server repo"
    exit
fi

source lib/lib.sh
source lib/include/update/cmake.sh

check_warnings
audit_code

log "current cmake build dir: ${CFG_GIT_PATH_MOD}/$(get_cmake_build_dir)"

if pgrep -f "$SERVER_UUID" > /dev/null
then
    suc -n "server is up and running '$SERVER_UUID'"
    if proc_in_screen "$SERVER_UUID" >/dev/null
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
    wrn "no server with this id found '$SERVER_UUID'"
fi

show_procs
log "port: $(get_tw_config sv_port 8303) ($(port_status))"

