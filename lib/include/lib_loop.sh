#!/bin/bash

# max failed starts - do not continue restarting the server
# when it failed to start x times.
# Failed starts are crashes during the first 5 seconds after server start.
MAX_FAILED_STARTS=3

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
    wrn "failed starts $failed_starts/$MAX_FAILED_STARTS"
    if [ "$failed_starts" -ge "$MAX_FAILED_STARTS" ]
    then
        err "ERROR: Reached failed starts threshold!"
        err "       You have to manually restart the server"
        err "       when it crashed after start too often."
        return 0
    fi
    return 1
}

