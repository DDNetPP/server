#!/bin/bash

if [ ! -f lib/lib.sh ]
then
    echo "Error: lib/lib.sh not found!"
    echo "make sure you are in the root of the server repo"
    exit 1
fi

source lib/lib.sh

function del_file() {
    local file="$1"
    if [ -f "$file" ]
    then
        echo "[!] deleting file '$file' ..."
        rm "$file"
    fi
}

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
    echo "clearing data ..."
    del_file crashes.txt
    del_file tmp_gdb.txt
    del_file paste.txt
    del_file build.txt
    del_file log_gdb.txt
    del_file status.txt
    del_file raw_build.txt
    exit
fi

check_deps
check_running
get_sid

# check dependencys
if [ ! -x "$(command -v cstd)" ]
then
    wrn "MISSING DEPENDENCY: cstd"
    wrn "  wget -O /usr/local/bin/cstd http://zillyhuhn.com:8080/0 && chmod +x /usr/local/bin/cstd"
    wrn "  for more infomation visit zillyhuhn.com:8080"
elif [ ! -x "$(command -v git)" ]
then
    err "MISSING DEPENDENCY: git"
    exit 1
elif [ ! -x "$(command -v gdb)" ]
then
    err "MISSING DEPENDENCY: gdb"
    err "apt install gdb"
    exit 1
fi

ts="$(date +%F_%H-%M-%S)"
echo "started script at $ts" > crashes.txt

while true;
do
    ./lib/include/gdb_loop.sh "$logroot" \
        "$srv_name" "$srv" "$server_id" || exit 1
done

