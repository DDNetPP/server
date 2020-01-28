#!/bin/bash

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

srv_name=fddrace

logfile=TeeworldsLogs/$srv_name/logs/${srv_name}_$(date +%F_%H-%M-%S).log
ts=$(date +%F_%H-%M-%S)
echo "started script at $ts" > crashes.txt

while true;
do
    echo "============= server start $ts =============" >> raw_gdb.txt
    gdb -ex='set confirm off' \
        -ex='set pagination off' \
        -ex='set logging file raw_gdb.txt' \
        -ex='set logging on' \
        -ex=run -ex=bt -ex=quit --args \
        ./${srv_name}_srv "logfile $logfile;#sid:fddrace-BlmapChill"
    ts=$(date +%F_%H-%M-%S)
    # filter out the thread spam
    grep -v '^\[New Thread' raw_gdb.txt | grep -v '^\[Thread' > tmp_gdb.txt
    mv tmp_gdb.txt raw_gdb.txt
    cat raw_gdb.txt | ./lib/echo_pipe.sh >> bt.txt
    cat raw_gdb.txt >> log_gdb.txt
    rm raw_gdb.txt
    echo "echo 'crash or shutdown $ts'" >> crashes.txt
    ./cmake_update.sh 2>&1 > raw_build.txt
    url="$(cstd raw_build.txt)"
    echo "echo $url" > paste.txt
    cat raw_build.txt | ./lib/echo_pipe.sh > build.txt
    echo "git status - $(date)" | ./lib/echo_pipe.sh > status.txt
    git status 2>&1 | ./lib/echo_pipe.sh >> status.txt
    sleep 5
done

