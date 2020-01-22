#!/bin/bash

if [ ! -f lib/lib.sh ]
then
    echo "Error: lib/lib.sh not found!"
    echo "make sure you are in the root of the server repo"
    exit 1
fi

source lib/lib.sh

get_sid


if echo $psaux | grep $server_id | grep -qv grep;
then
    pkill -f "$server_id"
    log "stopped server with id '$server_id'"
else
    wrn "no server with this id found '$server_id'"
fi
sleep 0.5 # give server time to shutdown
psaux=$(ps aux)
if echo $psaux | grep $srv_name | grep -qv grep;
then
    log "other proccesses containing '$srv_name' were found."
    log "you can stop them all."
    log "but keep it mind it could stop any application on your server not only tw server"
    log "+-------] running proccesses [--------+"
    ps axo cmd | grep $srv_name | grep -v "grep"
    log "+------------------------------------+"
    log "do you want to stop them all? [y/N]"
    read -r -n 1 yn
    echo ""
    if [[ "$yn" =~ [yY] ]]
    then
        pkill -f "./${srv_name}_srv_d"
        log "stopped all proccesses."
    else
        log "aborting stop script."
    fi
fi

