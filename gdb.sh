#!/bin/bash

if [ ! -f lib/lib.sh ]
then
    echo "Error: lib/lib.sh not found!"
    echo "make sure you are in the root of the server repo"
    exit 1
fi

source lib/lib.sh

check_deps
check_running
install_dep gdb

logfile="$logroot/$CFG_SRV_NAME/logs/${CFG_SRV_NAME}_$(date +%F_%H-%M-%S).log"
cache_logpath "$logfile"

gdb --args ./${CFG_BIN}_srv_d "logfile $logfile;#sid:$server_id"

