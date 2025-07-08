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
export COMMIT_HASH
if ! COMMIT_HASH="$(get_commit)"
then
	err "failed to get commit hash"
	exit 1
fi
git_patches="$(get_applied_git_patches)"

log_cmd=''
if is_cfg CFG_ENABLE_LOGGING
then
	log_cmd="logfile $logfile"
fi

read -rd '' run_cmd << EOF
$CFG_ENV_RUNTIME gdb \
    -ex='set confirm off' \
    -ex='set pagination off' \
    -ex='set disassembly-flavor intel' \
    -ex='handle SIGPIPE nostop noprint pass' \
    -ex='handle SIGINT nostop noprint pass' \
    -ex=run \
    --args \
    ./$CFG_BIN -f autoexec.cfg "$log_cmd;#sid:$SERVER_UUID:gdb.sh"
EOF

log "$run_cmd"
launch_commit="$(get_commit)"
bash -c "set -euo pipefail;$run_cmd"
log "build commit: $launch_commit"
if [ "$git_patches" != "" ]
then
	log "applied patches: $git_patches"
fi
