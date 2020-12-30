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

if [ "$1" == "--help" ] || [ "$1" == "-h" ]
then
    echo "usage: ./start.sh [map url]"
    echo ""
    echo "when no arguemnt provided a production server is started"
    echo "it is writing a logfile and running in the background"
    echo ""
    echo "when the map argument is provided a test server is started"
    echo "the map will be downloaded into maps/tmp/mapname.map"
    echo "and the server will be started with that map and running in the foreground"
    echo "no logfile will be written"
    exit 0
elif [ "$#" -gt 0 ]
then
    mapurl="$1"
    if ! [[ "$mapurl" =~ (http|www).*\.map ]]
    then
        err "invalid url '$mapurl'"
        exit 1
    fi
    if [ ! -d maps/ ]
    then
        err "maps directory not found."
        exit 1
    fi
    mkdir -p maps/tmp
    cd maps/tmp || exit 1
    mapname="${mapurl##*/}"
    if ! [[ "$mapname" =~ .map$ ]]
    then
        err "Failed to parse mapname '$mapname'"
        exit 1
    fi
    if [ -f "$mapname" ]
    then
        rm "$mapname"
    fi
    mapname="$(basename "$mapname" .map)"
    log "downloading map '$mapname' ..."
    wget "$mapurl"
    cd ../../
    read -rp 'password: ' pass
    log "starting server with password '$pass' ..."
    ./"$CFG_BIN" "sv_map tmp/$mapname;password $pass"
    exit 0
fi

if [ "$CFG_SERVER_TYPE" == "tem" ]
then
    logfile="$(pwd)/logs/tem/vanilla_tem_$(date +%F_%H-%M-%S).log"
    mkdir -p logs/tem
    cd "$CFG_TEM_PATH" || exit 1
    nohup ./start_tem.sh "$CFG_TEM_SETTINGS" "#sid:$server_id" > "$logfile" 2>&1 &
else # teeworlds
    logfile="$LOGS_PATH_FULL/${CFG_SRV_NAME}_$(date +%F_%H-%M-%S).log"
    cache_logpath "$logfile"

    run_cmd="nohup $CFG_ENV_RUNTIME ./$CFG_BIN \"#sid:$server_id\" > $logfile 2>&1 &"
    log "running:"
    tput bold
    echo "$run_cmd"
    tput sgr0
    eval "$run_cmd"

    show_log_file "$logfile"
fi

