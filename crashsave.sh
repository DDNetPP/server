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
get_sid

while true;
do
    logfile="$gitpath_log/$CFG_SRV_NAME/logs/${CFG_SRV_NAME}_$(date +%F_%H-%M-%S).log"
    ts_start=$(date +%F_%H-%M-%S)
    ./$CFG_BIN "#sid:$server_id" > "$logfile"
    ts_end=$(date +%F_%H-%M-%S)
    echo "+----------------------------------------+"
    echo ""
    figlet crash
    date
    echo ""
    echo "+----------------------------------------+"
    echo "echo crash or shutdown" >> crashes.txt
    echo "echo start: $ts_start" >> crashes.txt
    echo "echo crash: $ts_end" >> crashes.txt
    echo "echo ------------------" >> crashes.txt
done

