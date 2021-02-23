#!/bin/bash

# shellcheck disable=SC2009
function proc_in_screen() {
    local screen_pid
    local proc_pid
    local proc
    local _
    local proc_search="$1"
    local proc_names=()
    for screen_pid in $(screen -ls | grep ached | awk '{ print $1 }' | cut -d'.' -f1)
    do
        proc_pid="$(ps -el | grep "$screen_pid" | tail -n1 | awk '{ print $4 }')"
        # go 3 levels deeper to search for the running proc
        # screen -> ./gdb.sh -> gdb
        # screen -> loop_gdb.sh > gdb_loop.sh -> gdb
        for _ in {1..3}
        do
            proc_pid="$(ps -el | grep "$proc_pid" | tail -n1 | awk '{ print $4 }')"
        done
        proc_name="$(ps x | grep "$proc_pid" | head -n1)"
        if [[ "$proc_name" == *"$proc_search"* ]]
        then
            proc_names+=("$proc_name")
        fi
    done
    if [ "${#proc_names[@]}" -gt "0" ]
    then
        log "process found running in SCREEN"
        printf -- "-----------[ %3s processes found ]-----------\n" "${#proc_names[@]}"
        for proc in "${proc_names[@]}"
        do
            echo "  $proc"
        done
        echo "---------------------------------------------"
        return 0
    else
        return 1
    fi
}

