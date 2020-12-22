#!/bin/bash

if [ ! -f lib/lib.sh ]
then
    echo "Error: lib/lib.sh not found!"
    echo "make sure you are in the root of the server repo"
    exit 1
fi

source lib/lib.sh

get_sid
if [ -f lib/tmp/logfile.txt ]
then
    rm lib/tmp/logfile.txt
fi


if pgrep -f "$server_id"
then
    pkill -f "$server_id"
    log "stopped server with id '$server_id'"
else
    wrn "no server with this id found '$server_id'"
fi
sleep 0.5 # give server time to shutdown
if show_procs
then
    log "other processes containing '$CFG_BIN' were found."
    log "you can stop them all."
    log "but keep it mind it could stop any application on your server not only tw server"
    log "do you want to stop them all? [y/N]"
    read -r -n 1 yn
    echo ""
    if [[ "$yn" =~ [yY] ]]
    then
        pkill -f "./$CFG_BIN"
        log "stopped all processes."
    else
        log "aborting stop script."
    fi
fi

