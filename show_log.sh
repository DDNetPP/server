#!/bin/bash

if [ ! -f lib/lib.sh ]
then
    echo "Error: lib/lib.sh not found!"
    echo "make sure you are in the root of the server repo"
    exit 1
fi

source lib/lib.sh

show_latest_logs
