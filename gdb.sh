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

logfile="$LOGS_PATH_TW/$CFG_SRV_NAME/logs/${CFG_SRV_NAME}_$(date +%F_%H-%M-%S).log"
cache_logpath "$logfile"

gdb -ex=run --args ./$CFG_BIN "logfile $logfile;#sid:$server_id"

