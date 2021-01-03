#!/bin/bash

if [ ! -f lib/lib.sh ]
then
    echo "Error: lib/lib.sh not found!"
    echo "make sure you are in the root of the server repo"
    exit 1
fi

source lib/lib.sh

log -n "clean_twlog_pipe.sh ... "

if ! diff <(cat ./lib/test/data/vanilla07.log | ./lib/clean_twlog_pipe.sh --pickups=0) ./lib/test/data/vanilla07_clean.log
then
    echo "FAIL"
    err "--pickups=0 failed"
    exit 1
else
    echo "OK"
fi

