#!/bin/bash

if [ ! -f lib/lib.sh ]
then
    echo "Error: lib/lib.sh not found!"
    echo "make sure you are in the root of the server repo"
    exit 1
fi

source lib/lib.sh

check_deps "$1"
check_warnings
check_running
install_dep gdb
archive_gmon
restart_side_runner

logfile="$LOGS_PATH_FULL_TW/${CFG_SRV_NAME}_$(date +%F_%H-%M-%S)${CFG_LOG_EXT}"
cache_logpath "$logfile"

# https://stackoverflow.com/questions/18935446/program-received-signal-sigpipe-broken-pipe#18963142
# https://github.com/ddnet/ddnet/pull/3527
# we need "handle SIGPIPE nostop noprint pass"
# when running ddnet based servers because it uses curl
# and curl throws a sigpipe
# the ddnet code catches that but gdb catches it first and then crashes the server
# TODO: make this a gdb options config or use a gdbrc file and also include that in loop_gdb
export COMMIT_HASH="$(get_commit)"
run_cmd="$CFG_ENV_RUNTIME gdb -ex='handle SIGPIPE nostop noprint pass' -ex=run --args ./\"$CFG_BIN\" \"exec autoexec.cfg;logfile $logfile;#sid:$SERVER_UUID\""
log "$run_cmd"
launch_commit="$(get_commit)"
eval "$run_cmd"
log "commit: $launch_commit"
