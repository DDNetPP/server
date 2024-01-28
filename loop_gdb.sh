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
	echo "usage: $(basename "$0")"
	echo "parameters:"
	echo "--clear       deletes all tmp txt files"
	echo "description:"
	echo "runs server with gdb"
	echo "on crash saves backtrace to file and restarts"
	exit
elif [ "$1" == "--clear" ]
then
	p=logs/crashes
	log "clearing data ..."
	del_file crashes.txt
	del_file paste.txt
	del_file bt.txt
	del_file "$p/status.txt"
	del_file "$p/build.txt"
	del_file "$p/log_gdb.txt"
	del_file "$p/raw_gdb.txt"
	del_file "$p/raw_build.txt"
	del_file "$p/full_gdb.txt"
	exit
elif [ "$1" == "--yes" ] || [ "$1" == "-y" ]
then
	test
elif [ "$#" -gt "0" ]
then
	err "Error: unkown arg '$1' try '--help'"
	exit 1
fi

del_file "lib/tmp/failed_starts.txt"

check_deps "$1"
check_running

install_cstd
install_dep git
install_dep gdb

ts="$(date +%F_%H-%M-%S)"
echo "echo started script at $ts" > crashes.txt

while true;
do
    ./lib/include/gdb_loop.sh --loop || exit 1
done

