#!/bin/bash

if [ ! -f lib/lib.sh ]
then
    echo "Error: lib/lib.sh not found!"
    echo "make sure you are in the root of the server repo"
    exit 1
fi

source lib/lib.sh

arg_tool=massif

for arg in "$@"
do
	if [ "$arg" == "--help" ] || [ "$arg" == "-h" ]
	then
		echo "usage: ./valgrind.sh [OPTION]"
		echo "options:"
		echo "  --tool=massif           use valgrinds massif tool"
		echo "  --tool=memcheck         use valgrinds memcheck tool"
		echo "                          default tool: $arg_tool"
		exit 0
	elif [ "${arg::2}" == "--" ]
	then
		if [[ "$arg" == "--tool="* ]]
		then
			arg_tool="$(printf '%s' "$arg" | cut -d= -f2-)"
			if [ "$arg_tool" = massif ]
			then
				true
			elif [ "$arg_tool" = memcheck ]
			then
				true
			else
				err "Invalid valgrind tool '$arg_tool'"
				exit 1
			fi
		else
			err "invalid argument '$arg' see '--help'"
			exit 1
		fi
	else
		err "unexpected argument '$arg' see '--help'"
		exit 1
	fi
done

check_deps "$1"
check_warnings
check_running
install_dep valgrind
archive_gmon
restart_side_runner
die_if_asan_on_because valgrind

export COMMIT_HASH
if ! COMMIT_HASH="$(get_commit)"
then
	err "failed to get commit hash"
	exit 1
fi

logfile="$LOGS_PATH_FULL_TW/${CFG_SRV_NAME}_$(date +%F_%H-%M-%S)${CFG_LOG_EXT}"
cache_logpath "$logfile"

log_cmd='echo nologging'
if is_cfg CFG_ENABLE_LOGGING
then
	log_cmd="logfile $logfile"
fi

run_cmd=noop

if [ "$arg_tool" = "massif" ]
then
	massif_logpath="logs/massif_${COMMIT_HASH:-null}_$(date '+%F_%H-%M').out.txt"

	# traditionally massif also includes the pid with %p placeholder
	# but then it becomes tricky for us to log the logpath
	# because getting the pid only works at runtime
	# we can not use $$ because its a wrapped launcher
	# there should probably be a proper launch_cmd() helper
	# that can pritty print args and handle pid and exit codes
	# massif_logpath="${massif_logpath}.%p"

	read -rd '' run_cmd <<- EOF
	$CFG_ENV_RUNTIME valgrind \
		--tool=massif \
		--massif-out-file=$massif_logpath \
		./$CFG_BIN -f autoexec.cfg "$log_cmd;#sid:$SERVER_UUID:valgrind.sh"
	EOF
elif [ "$arg_tool" = "memcheck" ]
then
	read -rd '' run_cmd <<- EOF
	$CFG_ENV_RUNTIME valgrind \
		--tool=memcheck \
		--gen-suppressions=all \
		--suppressions=./lib/supp/memcheck.supp \
		--leak-check=full \
		--show-leak-kinds=all \
		./$CFG_BIN -f autoexec.cfg "$log_cmd;#sid:$SERVER_UUID:valgrind.sh"
	EOF
else
	err "Error: unsupported valgrind tool '$arg_tool'"
	exit 1
fi

log "$run_cmd"
git_patches="$(get_applied_git_patches)"
launch_commit="$(get_commit)"
bash -c "set -euo pipefail;$run_cmd"
log "build commit: $launch_commit"
if [ "$git_patches" != "" ]
then
	log "applied patches: $git_patches"
fi

if [ "$arg_tool" = "massif" ]
then
	log "created massif report at $massif_logpath"
	log "you can inspect it using this command:"
	echo ""
	echo -e "     ${BOLD}ms_print $massif_logpath${RESET}"
	echo ""
fi

