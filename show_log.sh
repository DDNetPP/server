#!/bin/bash

if [ ! -f lib/lib.sh ]
then
    echo "Error: lib/lib.sh not found!"
    echo "make sure you are in the root of the server repo"
    exit 1
fi

source lib/lib.sh

logpath=""
follow=""

for arg in "$@"
do
    if [ "$arg" == "--help" ] || [ "$1" == "-h" ]
    then
        echo "usage: ./show_log.sh [logname] [-f] [logname]"
        echo "options:"
        echo "  -h          show this help"
        echo "  -f          follows log using tail -f"
        echo "  logname     directory in ./logs/logname for local log types"
        exit 0
    elif [ "$arg" == "-f" ]
    then
        follow=-f
    elif [ "$logpath" == "" ]
    then
        logpath="$arg"
    fi
done

show_latest_logs "$follow" "$logpath"

