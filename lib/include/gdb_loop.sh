#!/bin/bash
# do not call this script directly
# this is called in loop_gdb.sh
# so updating the script without restarting it is possible

# max log size - delete logfile and start writing a new one when line count is reached
MAX_LOG_SIZE=5000

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

function check_logsize() {
    local logf="$1"
    if [ ! -f "$logf" ]
    then
        return
    fi
    local lines
    lines="$(wc -l < "$logf")"
    if [ "$?" != "0" ] || [ "$lines" == "" ]
    then
        err "ERROR: failed to compute logsize of file '$logf'"
    elif [ "$lines" -gt "$MAX_LOG_SIZE" ]
    then
        wrn "WARNING: logfile reached maximum size lines $lines/$MAX_LOG_SIZE"
        wrn "         deleting logfile '$logf' ..."
        rm "$logf"
    else
        log "log '$logf' lines $lines/$MAX_LOG_SIZE"
    fi
}

p=logs/crashes
mkdir -p "$p" || exit 1

check_logsize "$p/full_gdb.txt"
check_logsize "$p/log_gdb.txt"

ts=$(date +%F_%H-%M-%S)
log_filename="$CFG_SRV_NAME/logs/${CFG_SRV_NAME}_$ts.log"
logfile="$logroot/$log_filename"
logfile_absolute="$gitpath_log/$log_filename"
cache_logpath "$logfile"
if [ -f "$p/tmp_gdb.txt" ]
then
    rm "$p/tmp_gdb.txt"
fi
start_ts=$(date '+%Y-%m-%d %H:%M:%S')
echo "/============= server start $start_ts =============\\" >> "$p/full_gdb.txt"
gdb -ex='set confirm off' \
    -ex='set pagination off' \
    -ex=run \
    -ex="set logging file $p/tmp_gdb.txt" \
    -ex='set logging on' \
    -ex=bt \
    -ex='set logging off' \
    -ex="set logging file $p/full_gdb.txt" \
    -ex='set logging on' \
    -ex='echo (gdb) bt full\n' -ex='bt full' \
    -ex='echo (gdb) info registers\n' -ex='info registers' \
    -ex=quit --args \
    ./${CFG_BIN}_srv_d "logfile $logfile;#sid:$server_id"
stop_ts=$(date '+%Y-%m-%d %H:%M:%S')
echo "\\============= server stop  $stop_ts =============/" >> "$p/full_gdb.txt"
echo "/============= server start $start_ts =============\\" > "$p/raw_gdb.txt"
if [ ! -f "$logfile_absolute" ]
then
    logfile_absolute="$logfile_absolute.txt"
fi
if [ -f "$logfile_absolute" ]
then
    tail -n10 "$logfile_absolute" >> "$p/raw_gdb.txt"
    echo "" >> "$p/raw_gdb.txt"
else
    wrn "WARNING! logfile not found:"
    echo "$logfile_absolute"
fi
cat "$p/tmp_gdb.txt" >> "$p/raw_gdb.txt"
echo "\\============= server stop  $stop_ts =============/" >> "$p/raw_gdb.txt"
./lib/echo_pipe.sh "$p/raw_gdb.txt" > bt.txt
cat "$p/raw_gdb.txt" >> "$p/log_gdb.txt"
rm "$p/raw_gdb.txt"
log_err "gdb_loop.sh server $CFG_SRV_NAME crashed at $ts"
echo "echo \"crash or shutdown$ts\"" >> crashes.txt
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

