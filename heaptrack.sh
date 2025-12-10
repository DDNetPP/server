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
install_dep heaptrack
archive_gmon
restart_side_runner
die_if_asan_on_because heaptrack

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

heaptrack_logpath="logs/heaptrack_${COMMIT_HASH:-null}_$(date '+%F_%H-%M')"

# traditionally heaptrack also includes the pid with %p placeholder
# but then it becomes tricky for us to log the logpath
# because getting the pid only works at runtime
# we can not use $$ because its a wrapped launcher
# there should probably be a proper launch_cmd() helper
# that can pritty print args and handle pid and exit codes
# heaptrack_logpath="${heaptrack_logpath}.%p"

read -rd '' run_cmd <<- EOF
$CFG_ENV_RUNTIME heaptrack \
	--output "$heaptrack_logpath" \
	./$CFG_BIN -f autoexec.cfg "$log_cmd;#sid:$SERVER_UUID:heaptrack.sh"
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

log "created heaptrack report at $heaptrack_logpath"
log "you can inspect it using this command:"
echo ""
echo "     ${WHITE}heaptrack_print ${heaptrack_logpath}.zst | less${RESET}"
echo ""
log "or publish it via http and download locally to inspect with heaptrack gui version:"
echo ""
echo "     ${WHITE}cp ${heaptrack_logpath}.zst /var/www/html/tmp/${RESET}"
echo ""
log "then click here to download https://zillyhuhn.com/tmp/${heaptrack_logpath}.zst"
log "after downloading clean it up using this command:"
echo ""
echo "     ${WHITE}rm /var/www/html/tmp/${heaptrack_logpath}.zst${RESET}"
echo ""
