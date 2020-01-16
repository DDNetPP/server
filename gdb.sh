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
get_sid

logfile="$gitpath_log/TeeworldsLogs/$srv_name/logs/${srv_name}_$(date +%F_%H-%M-%S).log"

gdb --args ./${srv}_srv_d "logfile $logfile;#sid:$server_id"

