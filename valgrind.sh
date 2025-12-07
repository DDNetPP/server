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

read -rd '' run_cmd << EOF
$CFG_ENV_RUNTIME valgrind \
	--tool=massif \
	./$CFG_BIN -f autoexec.cfg "$log_cmd;#sid:$SERVER_UUID:valgrind.sh"
EOF

# valgrind \
# 	--tool=memcheck \
# 	--gen-suppressions=all \
# 	--suppressions=./lib/supp/memcheck.supp \
# 	--leak-check=full \
# 	--show-leak-kinds=all \

log "$run_cmd"
git_patches="$(get_applied_git_patches)"
launch_commit="$(get_commit)"
bash -c "set -euo pipefail;$run_cmd"
log "build commit: $launch_commit"
if [ "$git_patches" != "" ]
then
	log "applied patches: $git_patches"
fi

