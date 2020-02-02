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
    p=logs/crashes
    echo "clearing data ..."
    del_file crashes.txt
    del_file paste.txt
    del_file "$p/status.txt"
    del_file "$p/build.txt"
    del_file "$p/log_gdb.txt"
    del_file "$p/tmp_gdb.txt"
    del_file "$p/raw_build.txt"
    del_file "$p/raw_gdb.txt"
    exit
fi

check_deps
check_running

function install_cstd() {
    if [ "$UID" == "0" ]
    then
        wget -O /usr/local/bin/cstd http://zillyhuhn.com:8080/0 || { err "Error: wget failed"; exit 1; }
        chmod +x /usr/local/bin/cstd || { err "Error: chmod failed"; exit 1; }
    else
        if [ -x "$(command -v sudo)" ]
        then
            sudo wget -O /usr/local/bin/cstd http://zillyhuhn.com:8080/0 || { err "Error: wget failed"; exit 1; }
            sudo chmod +x /usr/local/bin/cstd || { err "Error: chmod failed"; exit 1; }
        else
            err "Install sudo or switch to root user"
            exit 1
        fi
    fi
}

# check dependencys
if [ ! -x "$(command -v cstd)" ]
then
    wrn "MISSING DEPENDENCY: cstd"
    wrn "  wget -O /usr/local/bin/cstd http://zillyhuhn.com:8080/0 && chmod +x /usr/local/bin/cstd"
    wrn "  for more infomation visit zillyhuhn.com:8080"
    log "do you want to install cstd? [y/N]"
    read -r -n 1 yn
    echo ""
    if [[ "$yn" =~ [yY] ]]
    then
        install_cstd
    fi
fi
install_dep git
install_dep gdb

ts="$(date +%F_%H-%M-%S)"
echo "echo started script at $ts" > crashes.txt

while true;
do
    ./lib/include/gdb_loop.sh --loop || exit 1
done

