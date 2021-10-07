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
source lib/include/lib_loop.sh

pre_loop_run

function check_logsize() {
    local logf="$1"
    if [ ! -f "$logf" ]
    then
        return
    fi
    local lines
    if ! lines="$(wc -l < "$logf")" || [ "$lines" == "" ]
    then
        err "ERROR: failed to compute logsize of file '$logf'"
        exit 1
    elif [ "$lines" -gt "$MAX_LOG_SIZE" ]
    then
        wrn "WARNING: logfile reached maximum size lines $lines/$MAX_LOG_SIZE"
        wrn "         deleting logfile '$logf' ..."
        rm "$logf"
    else
        log "log '$logf' lines $lines/$MAX_LOG_SIZE"
    fi
}

start_ts_slug=$(date '+%Y-%m-%d_%H-%M-%S')
gdb_corefile=""
gdb_corefile_cmd=""
if is_cfg CFG_GDB_DUMP_CORE
then
    log "dumping core is turned on (generate-core-file)"
    gdb_corefile="core_dumps/core_${start_ts_slug}:$(get_commit)"
    gdb_corefile_cmd="-ex='generate-core-file $gdb_corefile'"
    mkdir -p core_dumps/ || exit 1
fi

p=logs/crashes
mkdir -p "$p" || exit 1

check_logsize "$p/full_gdb.txt"
check_logsize "$p/log_gdb.txt"

ts=$(date +%F_%H-%M-%S)
log_filename="${CFG_SRV_NAME}_$ts${CFG_LOG_EXT}"
logfile="$LOGS_PATH_FULL_TW/$log_filename"
logfile_absolute="$LOGS_PATH_FULL/$log_filename"
cache_logpath "$logfile"
if [ -f "$p/tmp_gdb.txt" ]
then
    rm "$p/tmp_gdb.txt"
fi

custom_gdb=""
if [ "$CFG_GDB_CMDS" != "" ]
then
    custom_gdb="-ex='echo (gdb) $CFG_GDB_CMDS\\n' -ex='$CFG_GDB_CMDS'"
    log "custom gdb command '$custom_gdb'"
fi

read -rd '' GDB_CMD << EOF
$CFG_ENV_RUNTIME gdb -ex='set confirm off' \
    -ex='set pagination off' \
    -ex='set disassembly-flavor intel' \
    -ex=run \
    -ex="set logging file $p/tmp_gdb.txt" \
    -ex='set logging on' \
    -ex=bt \
    -ex='set logging off' \
    -ex="set logging file $p/full_gdb.txt" \
    -ex='set logging on' \
    -ex='echo (gdb) bt full\\n' -ex='bt full' \
    -ex='echo (gdb) info registers\\n' -ex='info registers' \
    -ex='echo (gdb) x/20i \$rip-20\\n' -ex='x/20i \$rip-20' \
    -ex='echo (gdb) list\\n' -ex='list' \
    -ex='echo (gdb) info threads\\n' -ex='info threads' \
    $custom_gdb \
    $gdb_corefile_cmd \
    -ex=quit --args \
    ./$CFG_BIN "logfile $logfile;#sid:$SERVER_UUID:loop_script"
EOF
start_ts=$(date '+%Y-%m-%d %H:%M:%S')
{
    echo "/============= server start $start_ts =============\\"
    echo "build commit: $(get_commit)"
    echo "gdb ./bin/backup/$(get_commit) $gdb_corefile"
    echo "objdump -dCS -M intel bin/backup/$(get_commit) > ./lib/tmp/debug.asm && vim ./lib/tmp/debug.asm"
    echo "python -c 'print(hex(0xbabe + 10))'"
} >> "$p/full_gdb.txt"
echo ""
eval "$GDB_CMD"
echo ""
log "executed: '$GDB_CMD'"
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

start_secs="$(date --date "$start_ts" +%s)"
stop_secs="$(date --date "$stop_ts" +%s)"
runtime="$((stop_secs - start_secs))"

log "server runtime: $runtime seconds"
if failed_too_many_starts "$runtime"
then
    exit 1
fi

post_loop_run

./update.sh &> "$p/raw_build.txt"
if is_cfg CFG_CSTD
then
    url="$(cstd "$p/raw_build.txt")"
    echo "echo $url" > paste.txt
fi
./lib/echo_pipe.sh "$p/raw_build.txt" > "$p/build.txt"
echo "git status - $(date)" | ./lib/echo_pipe.sh > "$p/status.txt"
git status | ./lib/echo_pipe.sh >> "$p/status.txt"

post_logs

if [ -f lib/var/loop_gdb_on_restart.sh ]
then
    log "found custom loop_gdb_on_restart.sh script ... executing."
    lib/var/loop_gdb_on_restart.sh
fi
log "sleeping $RESTART_DELAY seconds ... press CTRL-C now to stop the server"
sleep $RESTART_DELAY

