#!/bin/bash

if [ ! -f lib/lib.sh ]
then
    echo "Error: lib/lib.sh not found!"
    echo "make sure you are in the root of the server repo"
    exit 1
fi

source lib/lib.sh

if [ "$1" == "--help" ] || [ "$1" == "-h" ]
then
    echo "usage: ./show_log.sh [-f]"
    echo "options:"
    echo "  -f      follows log using tail -f"
    exit 0
fi

show_latest_logs "$1"
