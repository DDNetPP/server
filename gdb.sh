#!/bin/bash

if [ ! -f lib/lib.sh ]
then
    echo "Error: lib/lib.sh not found!"
    echo "make sure you are in the root of the server repo"
    exit
fi

source lib/lib.sh

check_deps
check_running

logfile="$gitpath/TeeworldsLogs/$srv/logs/${srv}_$(date +%F_%H-%M-%S).log"

gdb --args ./$srv_bin "logfile $logfile"

show_log
