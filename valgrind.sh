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
install_dep valgrind
archive_gmon
restart_side_runner

is_asan_runtime() {
	if printf '%s' "$CFG_ENV_RUNTIME" | grep -qE '(env_san.sh|fsanitize)'
	then
		return 0
	fi
	return 1
}

is_asan_build() {
	if printf '%s' "$CFG_ENV_BUILD" | grep -qE '(env_san.sh|fsanitize)'
	then
		return 0
	fi
	return 1
}

if is_asan_runtime || is_asan_build
then
	err "Error: in your server.cnf you enabled a sanitizer already"
	err "       valgrind does not work well when combined with asan and ubsan"
	err "       go to your server.cnf and check where you set env_build and env_runtime"
	err "       their current values are:"
	err ""
	err "        env_build=$CFG_ENV_BUILD"
	err "        env_runtime=$CFG_ENV_RUNTIME"
	err ""
	exit 1
fi

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

valgrind_tool=massif
run_cmd=noop

if [ "$valgrind_tool" = "massif" ]
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
elif [ "$valgrind_tool" = "memcheck" ]
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
	err "Error: unsupported valgrind tool '$valgrind_tool'"
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

if [ "$valgrind_tool" = "massif" ]
then
	log "created massif report at $massif_logpath"
	log "you can inspect it using this command:"
	echo ""
	echo "     $(tput bold)ms_print $massif_logpath$(tput sgr0)"
	echo ""
fi

