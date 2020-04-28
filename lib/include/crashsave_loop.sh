#!/bin/bash
# do not call this script directly
# this is called in crashsave.sh
# so updating the script without restarting it is possible

# restart delay - sleep time after server crash/shutdown
# recommended is '5' which is 5 seconds
# could also be '1m' for 1 minute (passed to sleep command)
# WARNING: using something other than seconds might need some changes in the script
RESTART_DELAY=5

# max failed starts - do not continue restarting the server
# when it failed to start x times.
# Failed starts are crashes during the first 5 seconds after server start.
MAX_FAILED_STARTS=3

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

logfile="$logroot/$CFG_SRV_NAME/logs/${CFG_SRV_NAME}_$(date +%F_%H-%M-%S).log"
start_ts=$(date '+%Y-%m-%d %H:%M:%S')
./$CFG_BIN "logfile $logfile;#sid:$server_id"
exitcode="$?"
stop_ts=$(date '+%Y-%m-%d %H:%M:%S')
echo "+----------------------------------------+"
echo ""
figlet crash
echo "exitcode=$exitcode"
date
echo ""
echo "+----------------------------------------+"
{
    echo "echo crash or shutdown exitcode=$exitcode"
    echo "echo start: $start_ts"
    echo "echo crash: $stop_ts"
    echo "echo ------------------"
} >> crashes.txt

./cmake_update.sh > "$p/raw_build.txt"
url="$(cstd "$p/raw_build.txt")"
echo "echo $url" > paste.txt
./lib/echo_pipe.sh "$p/raw_build.txt" > "$p/build.txt"
echo "git status - $(date)" | ./lib/echo_pipe.sh > "$p/status.txt"
git status | ./lib/echo_pipe.sh >> "$p/status.txt"

start_secs="$(date --date "$start_ts" +%s)"
stop_secs="$(date --date "$stop_ts" +%s)"
runtime="$((stop_secs - start_secs))"

log "server runtime: $runtime seconds"
if [ "$runtime" -lt "5" ]
then
    mkdir -p lib/tmp
    failed_starts=0
    if [ -f lib/tmp/failed_starts.txt ]
    then
        failed_starts="$(cat lib/tmp/failed_starts.txt)"
    fi
    failed_starts="$((failed_starts + 1))"
    echo "$failed_starts" > lib/tmp/failed_starts.txt
    wrn "WARNING: Server runtime too short!"
    wrn "         if the server crashes during first 5 seconds"
    wrn "         this gets tracked as failed start."
    wrn "failed starts $failed_starts/$MAX_FAILED_STARTS"
    if [ "$failed_starts" -ge "$MAX_FAILED_STARTS" ]
    then
        err "ERROR: Reached failed starts threshold!"
        err "       You have to manually restart the server"
        err "       when it crashed after start too often."
        exit 1
    fi
fi
log "sleeping $RESTART_DELAY seconds ... press CTRL-C now to stop the server"
sleep $RESTART_DELAY
