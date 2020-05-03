#!/bin/bash
# F-DDrace accounts parser
# https://github.com/fokkonaut/F-DDrace/blob/3a41550df2502ca304d79465706e6fd52b951b5f/src/game/server/gamecontext.cpp#L3826-L3862

FDDR_PURGE_FILE=/tmp/fddr-purge.txt

function fddr.parse_account() {
    account=$1
    if [ ! -f "$account" ]
    then
        echo "Error file not found '$account'"
        exit 1
    fi
    linenum=0
    while IFS= read -r line
    do
        if [ "$linenum" == "0" ]; then
            port="$line"
        elif [ "$linenum" == "1" ]; then
            logged_in="$line"
        elif [ "$linenum" == "2" ]; then
            disabled="$line"
        elif [ "$linenum" == "3" ]; then
            password="$line"
        elif [ "$linenum" == "4" ]; then
            username="$line"
        elif [ "$linenum" == "5" ]; then
            client_id="$line"
        elif [ "$linenum" == "6" ]; then
            level="$line"
        elif [ "$linenum" == "7" ]; then
            xp="$line"
        elif [ "$linenum" == "8" ]; then
            money="$line"
        elif [ "$linenum" == "9" ]; then
            kills="$line"
        elif [ "$linenum" == "10" ]; then
            deaths="$line"
        elif [ "$linenum" == "11" ]; then
            police="$line"
        elif [ "$linenum" == "12" ]; then
            survival_kills="$line"
        elif [ "$linenum" == "13" ]; then
            survival_wins="$line"
        elif [ "$linenum" == "14" ]; then
            spooky_ghost="$line"
        elif [ "$linenum" == "15" ]; then
            money0="$line"
        elif [ "$linenum" == "16" ]; then
            money1="$line"
        fi
        linenum="$((linenum+1))"
    done < "$account"
}

function fddr.print_account() {
    path="$1"
    fddr.parse_account "$path"
    echo "[ === '$username' === ]"
    echo "file: $path"
    echo "password: $password"
    echo "level: $level xp: $xp"
    echo "money: $money"
    echo "$money0"
    echo "$money1"
    echo "kills: $kills deaths: $deaths"
}

function fddr.read_database() {
    :>"$FDDR_PURGE_FILE"
    for acc in ./accounts/*.acc
    do
        fddr.parse_account "$acc" || exit 1
        if [[ "$money" == "0" ]] && [[ "$xp" == "0" ]]
        then
            echo "$acc" >> "$FDDR_PURGE_FILE"
            fddr.print_account "$acc"
        fi
    done
}

function fddr.read_purgefile() {
    while IFS= read -r line
    do
        fddr.print_account "$line"
    done < "$FDDRtPURGE_FILE"
}

fdrr.read_database
fdrr.read_purgefile

