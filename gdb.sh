#!/bin/bash

if [ ! -f lib/lib.sh ]
then
    echo "Error: lib/lib.sh not found!"
    echo "make sure you are in the root of the server repo"
    exit 1
fi

source lib/lib.sh

arg_interactive=0
for arg in "$@"
do
	if [ "$arg" = "-i" ]
	then
		arg_interactive=1
	elif [ "$arg" = "-h" ] || [ "$arg" = "--help" ]
	then
		echo "usage: ./gdb.sh [yes|-i]"
		echo "description:"
		echo " starts the server with gdb it will drop into the"
		echo " interactive gdb console on crash and until then"
		echo " it runs like a production server with all the side runners"
		echo " and logging setup"
		echo "parameters:"
		echo " 'yes' - to have a non interactive dependency check"
		echo " '-i' - to start in interactive mode"
		echo "        it will also open the gdb prompt before the launch"
		echo "        so you can set breakpoints and then call run"
		exit 0
	fi
done

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

log_cmd='echo nologging'
if is_cfg CFG_ENABLE_LOGGING
then
	log_cmd="logfile $logfile"
fi

ex_run='-ex=run'
if [ "$arg_interactive" = 1 ]
then
	ex_run=''
fi

read -rd '' run_cmd << EOF
$CFG_ENV_RUNTIME gdb \
    -ex='set confirm off' \
    -ex='set pagination off' \
    -ex='set disassembly-flavor intel' \
    -ex='handle SIGPIPE nostop noprint pass' \
    -ex='handle SIGINT nostop noprint pass' \
    ${ex_run} \
    --args \
    ./$CFG_BIN -f autoexec.cfg "$log_cmd;#sid:$SERVER_UUID:gdb.sh"
EOF

log "$run_cmd"
git_patches="$(get_applied_git_patches)"
launch_commit="$(get_commit)"
bash -c "set -euo pipefail;$run_cmd"
log "build commit: $launch_commit"
if [ "$git_patches" != "" ]
then
	log "applied patches: $git_patches"
fi
