#!/bin/bash

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
    cat raw_gdb.txt | ./echo_pipe.sh >> bt.txt
    cat raw_gdb.txt >> log_gdb.txt
    rm raw_gdb.txt
    echo "echo 'crash or shutdown $ts'" >> crashes.txt
    ./update.sh 2>&1 > raw_build.txt
    url="$(cstd raw_build.txt)"
    echo "echo $url" > paste.txt
    cat raw_build.txt | ./echo_pipe.sh > build.txt
    echo "git status - $(date)" > status.txt
    git status 2>&1 >> status.txt
    sleep 5
done

