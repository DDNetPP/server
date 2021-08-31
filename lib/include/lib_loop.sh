#!/bin/bash

# max failed starts warning - do not continue restarting the server until new commit
# when it failed to start x times.
# Failed starts are crashes during the first 5 seconds after server start.
MAX_FAILED_STARTS_WARNING=3


# max failed starts error - abort the script
MAX_FAILED_STARTS_ERROR=6

function failed_too_many_starts() {
    local runtime="$1"
    local failed_starts=0
    local last_failed_start
    last_failed_start="$(date '+%F')"
    if [ "$runtime" -gt "5" ]
    then
        return 1
    fi
    mkdir -p lib/tmp
    if [ -f lib/tmp/failed_starts.txt ]
    then
        last_failed_start="$(tail -n1 lib/tmp/failed_starts.txt)"
        # reset failed restarts every day
        if [ "$last_failed_start" != "$(date '+%F')" ]
        then
            failed_starts=0
        else
            failed_starts="$(head -n1 lib/tmp/failed_starts.txt)"
        fi
    fi
    failed_starts="$((failed_starts + 1))"
    echo "$failed_starts" > lib/tmp/failed_starts.txt
    date '+%F' >> lib/tmp/failed_starts.txt
    wrn "WARNING: Server runtime too short!"
    wrn "         if the server crashes during first 5 seconds"
    wrn "         this gets tracked as failed start."
    wrn "failed starts $failed_starts/$MAX_FAILED_STARTS_ERROR"
    if [ "$failed_starts" -ge "$MAX_FAILED_STARTS_ERROR" ]
    then
        err "ERROR: Reached failed starts threshold!"
        err "       You have to manually restart the server"
        err "       when it crashed after start too often."
        return 0
    fi
    if [ "$failed_starts" -ge "$MAX_FAILED_STARTS_WARNING" ]
    then
        wrn "WARNING: Server failed to start $failed_starts times!"
        wrn "         Server will not start before there is a new commit"
        wait_for_new_mod_commit
    fi
    return 1
}

function wait_for_new_mod_commit() {
    local old_commit
    (
        cd "$CFG_GIT_PATH_MOD" || exit 1
        old_commit="$(git rev-parse HEAD)"
        while true
        do
            git pull
            if [ "$old_commit" != "$(git rev-parse HEAD)" ]
            then
                return
            fi
            log "waiting for new mod update ..."
            sleep 30
        done
    )
}

function post_logs() {
    if [ "$CFG_POST_LOGS_DIR" == "" ]
    then
        return
    fi
    log "copying logs to $CFG_POST_LOGS_DIR"
    p=logs/crashes
    save_copy "$p/status.txt" "$CFG_POST_LOGS_DIR"
    save_copy "$p/raw_build.txt" "$CFG_POST_LOGS_DIR"
    save_copy "$p/log_gdb.txt" "$CFG_POST_LOGS_DIR"
    save_copy "$p/full_gdb.txt" "$CFG_POST_LOGS_DIR"
    save_copy crashes.txt "$CFG_POST_LOGS_DIR"
}

function pre_loop_run() {
    check_dir_size
    restart_side_runner
    archive_gmon
}

function post_loop_run() {
	save_move nul logs
	save_move delay.txt logs
}

