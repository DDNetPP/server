#!/bin/bash

if [ ! -f lib/lib.sh ]
then
    echo "Error: lib/lib.sh not found!"
    echo "make sure you are in the root of the server repo"
    exit 1
fi

source lib/lib.sh

check_deps "$1"
check_warnings
check_running
install_dep gdb
archive_gmon

logfile="$LOGS_PATH_FULL_TW/${CFG_SRV_NAME}_$(date +%F_%H-%M-%S)${CFG_LOG_EXT}"
cache_logpath "$logfile"

run_cmd="$CFG_ENV_RUNTIME gdb -ex=run --args ./\"$CFG_BIN\" \"logfile $logfile;#sid:$SERVER_UUID\""
log "$run_cmd"
eval "$run_cmd"

