#!/bin/bash
# do not call this script directly
# this is called in loop_gdb.sh
# so updating the script without restarting it is possible

if [ "$1" != "--loop" ]
then
    echo "do not call this script manually!"
    exit 1
fi

if [ ! -f lib/lib.sh ]
then
    echo "Error: lib/lib.sh not found!"
    echo "make sure you are in the root of the server repo"
    exit 1
fi

source lib/lib.sh

p=logs/crashes
mkdir -p "$p" || exit 1

ts=$(date +%F_%H-%M-%S)
logfile="$logroot/$srv_name/logs/${srv_name}_$ts.log"
cache_logpath "$logfile"
echo "============= server start $ts =============" >> "$p/raw_gdb.txt"
gdb -ex='set confirm off' \
    -ex='set pagination off' \
    -ex="set logging file $p/raw_gdb.txt" \
    -ex='set logging on' \
    -ex=run -ex=bt -ex='quit $_exitcode' --args \
    ./${srv}_srv_d "logfile $logfile;#sid:$server_id"
if [ "$?" != "0" ]
then
    # filter out the thread spam
    grep -v '^\[New Thread' "$p/raw_gdb.txt" | grep -v '^\[Thread' > "$p/tmp_gdb.txt"
    mv "$p/tmp_gdb.txt" "$p/raw_gdb.txt"
    cat "$p/raw_gdb.txt" | ./lib/echo_pipe.sh >> bt.txt
    cat "$p/raw_gdb.txt" >> "$p/log_gdb.txt"
    rm "$p/raw_gdb.txt"
    echo "echo 'crash $ts'" >> crashes.txt
else
    echo "echo 'shutdown $ts'" >> crashes.txt
fi
./cmake_update.sh > "$p/raw_build.txt"
url="$(cstd "$p/raw_build.txt")"
echo "echo $url" > paste.txt
cat "$p/raw_build.txt" | ./lib/echo_pipe.sh > "$p/build.txt"
echo "git status - $(date)" | ./lib/echo_pipe.sh > "$p/status.txt"
git status | ./lib/echo_pipe.sh >> "$p/status.txt"
sleep 5

