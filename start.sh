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

logfile="$gitpath_log/$srv_name/logs/${srv_name}_$(date +%F_%H-%M-%S).log"
cache_logpath "$logfile"

nohup ./${srv}_srv_d "#sid:$server_id" > "$logfile" 2>&1 &

show_logs
