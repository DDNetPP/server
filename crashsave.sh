#!/bin/bash

if [ ! -f lib/lib.sh ]
then
    echo "Error: lib/lib.sh not found!"
    echo "make sure you are in the root of the server repo"
    exit 1
fi

source lib/lib.sh

del_file "lib/tmp/failed_starts.txt"

check_deps
check_running
get_sid

while true;
do
    ./lib/include/crashsave_loop.sh --loop || exit 1
done

