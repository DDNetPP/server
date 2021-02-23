#!/bin/bash
# do not call this script directly
# this is called in crashsave.sh
# so updating the script without restarting it is possible

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

restart_side_runner
archive_gmon

if is_cfg CFG_GDB_DUMP_CORE
then
    log "dumping core is turned on (generate-core-file)"
    ulimit -c unlimited
    mkdir -p core_dumps/ || exit 1
fi

p=logs/crashes
mkdir -p "$p" || exit 1

logfile="$LOGS_PATH_FULL_TW/${CFG_SRV_NAME}_$(date +%F_%H-%M-%S)${CFG_LOG_EXT}"
start_ts_slug=$(date '+%Y-%m-%d_%H-%M-%S')
start_ts=$(date '+%Y-%m-%d %H:%M:%S')

run_cmd="$CFG_ENV_RUNTIME ./$CFG_BIN 'logfile $logfile;#sid:$server_id'"
log "running:"
tput bold
echo "$run_cmd"
tput sgr0
eval "$run_cmd"

exitcode="$?"
if is_cfg CFG_GDB_DUMP_CORE
then
    for core in ./core.*
    do
        [[ -e "$core" ]] || break

        corefile="core_dumps/core_${start_ts_slug}:$(get_commit)"
        log "saving $corefile ..."
        mv "$core" "$corefile"
    done
fi
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

start_secs="$(date --date "$start_ts" +%s)"
stop_secs="$(date --date "$stop_ts" +%s)"
runtime="$((stop_secs - start_secs))"

log "server runtime: $runtime seconds"
if failed_too_many_starts "$runtime"
then
    exit 1
fi

./update.sh > "$p/raw_build.txt"
if is_cfg CFG_CSTD
then
    url="$(cstd "$p/raw_build.txt")"
    echo "echo $url" > paste.txt
fi
./lib/echo_pipe.sh "$p/raw_build.txt" > "$p/build.txt"
echo "git status - $(date)" | ./lib/echo_pipe.sh > "$p/status.txt"
git status | ./lib/echo_pipe.sh >> "$p/status.txt"

post_logs

log "sleeping $RESTART_DELAY seconds ... press CTRL-C now to stop the server"
sleep $RESTART_DELAY

