#!/bin/bash

if [ ! -f lib/lib.sh ]
then
    echo "Error: lib/lib.sh not found!"
    echo "make sure you are in the root of the server repo"
    exit 1
fi

source lib/lib.sh

if [ "$#" == "0" ] || [ "$1" == "--help" ] || [ "$1" == "-h" ]
then
    echo "usage: ./log_votes.sh <output directory> [log path]"
    echo "will get the logpath from the server.cnf or second argument"
    echo "and then creates multiple files"
    echo "holding all vote reasons for kick and spec votes"
    echo "works with 0.7 servers only"
    exit 0
fi

OUTPUT="$1"
LOGPATH="$CFG_LOGS_PATH"
if [ "$2" != "" ]
then
    LOGPATH="$2"
fi

yes_all=0

function lv.check_file() {
    local file
    file="$1"
    if [ "${yes_all}" == "1" ]; then return; fi;
    if [ -f "$file" ]
    then
        wrn "WARNING: file '$file' already exist in '$output'"
        log "do you want to continue?"
        log "[N]abort [y]yes [a]yes to all"
        yn=""
        read -r -n 1 yn
        echo ""
        if [[ "$yn" =~ [yY] ]]
        then
            return
        elif [[ "$yn" =~ [aA] ]]
        then
            yes_all=1
            return
        else
            log "aborting..."
            exit 1
        fi
    fi
}

function get_vote_reasons() {
    local logpath="$1"
    local output="$2"
    if [ ! -d "$output" ]
    then
        err "Error: directory '$output' does not exist."
        exit 1
    fi

    lv.check_file "$output/votes_raw.txt"
    lv.check_file "$output/votes_count.txt"
    lv.check_file "$output/votes_lower.txt"

    while IFS= read -r line; do
        echo "${line:8:-5}"
    done < <( \
        grep -Phr " voted (kick|spectate)" "$logpath" | \
        grep -v 'No reason given' | \
        grep -o "reason='.*' cmd" | \
        sort \
    ) > "$output/votes_raw.txt"

    uniq -c "$output/votes_raw.txt" | \
        sort -nr > "$output/votes_count.txt"

    awk '{print tolower($0)}' < "$output/votes_raw.txt" | \
        uniq -c | sort -nr > "$output/votes_lower.txt"
}

get_vote_reasons "$LOGPATH" "$OUTPUT"

