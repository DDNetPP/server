#!/bin/bash

if [ ! -f lib/lib.sh ]
then
    echo "Error: lib/lib.sh not found!"
    echo "make sure you are in the root of the server repo"
    exit
fi

source lib/lib.sh

if echo $psaux | grep $server_id | grep -qv grep;
then
    suc "server is up and running '$server_id'"
    check_logpath
    exit
else
    wrn "no server with this id found '$server_id'"
fi

show_procs

