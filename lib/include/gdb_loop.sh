#!/bin/bash
# do not call this script directly
# this is called in loop_gdb.sh
# so updating the script without restarting it is possible

if [ "$#" != "4" ]
then
    echo "do not call this script manually!"
    exit 1
fi

logroot="$1"
srv_name="$2"
srv="$3"
server_id="$4"

ts=$(date +%F_%H-%M-%S)
logfile="$logroot/$srv_name/logs/${srv_name}_$ts.log"
cache_logpath "$logfile"
echo "============= server start $ts =============" >> raw_gdb.txt
gdb -ex='set confirm off' \
    -ex='set pagination off' \
    -ex='set logging file raw_gdb.txt' \
    -ex='set logging on' \
    -ex=run -ex=bt -ex=quit --args \
    ./${srv}_srv_d "logfile $logfile;#sid:$server_id"
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

