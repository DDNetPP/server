#!/bin/bash

if [ ! -f lib/lib.sh ]
then
    echo "Error: lib/lib.sh not found!"
    echo "make sure you are in the root of the server repo"
    exit 1
fi

source lib/lib.sh

server_pid="$(pgrep -f "$SERVER_UUID")"

if [ "$server_pid" = "" ]
then
	err "Server process not found. Is the server running?"
	exit 1
fi

log "run the following command as root:"
echo ""
echo "  ./lib/_dump_memory.sh $server_pid"
echo ""
