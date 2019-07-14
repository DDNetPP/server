#!/bin/bash

if [ ! -f lib/lib.sh ]
then
    echo "Error: lib/lib.sh not found!"
    echo "make sure you are in the root of the server repo"
    exit
fi

source lib/lib.sh

check_srvtxt
get_sid


if echo $psaux | grep $server_id | grep -qv grep;
then
    suc "server is up and running '$server_id'"
    exit
else
    wrn "no server with this id found '$server_id'"
fi
if echo $psaux | grep $srv_name | grep -qv grep;
then
    log "other proccesses containing '$srv_name' were found."
    log "+-------] running proccesses[--------+"
    ps axo cmd | grep $srv_name | grep -v "grep"
    log "+------------------------------------+"
fi

