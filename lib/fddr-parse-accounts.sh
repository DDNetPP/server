#!/bin/bash
# F-DDrace accounts parser
# https://github.com/fokkonaut/F-DDrace/blob/3a41550df2502ca304d79465706e6fd52b951b5f/src/game/server/gamecontext.cpp#L3826-L3862

FDDR_PURGE_FILE=/tmp/fddr-purge.txt
FDDR_ACC_PATH=./accounts

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
            acc_port="$line"
        elif [ "$linenum" == "1" ]; then
            acc_logged_in="$line"
        elif [ "$linenum" == "2" ]; then
            acc_disabled="$line"
        elif [ "$linenum" == "3" ]; then
            acc_password="$line"
        elif [ "$linenum" == "4" ]; then
            acc_username="$line"
        elif [ "$linenum" == "5" ]; then
            acc_client_id="$line"
        elif [ "$linenum" == "6" ]; then
            acc_level="$line"
        elif [ "$linenum" == "7" ]; then
            acc_xp="$line"
        elif [ "$linenum" == "8" ]; then
            acc_money="$line"
        elif [ "$linenum" == "9" ]; then
            acc_kills="$line"
        elif [ "$linenum" == "10" ]; then
            acc_deaths="$line"
        elif [ "$linenum" == "11" ]; then
            acc_police="$line"
        elif [ "$linenum" == "12" ]; then
            acc_survival_kills="$line"
        elif [ "$linenum" == "13" ]; then
            acc_survival_wins="$line"
        elif [ "$linenum" == "14" ]; then
            acc_spooky_ghost="$line"
        elif [ "$linenum" == "15" ]; then
            acc_money0="$line"
        elif [ "$linenum" == "16" ]; then
            acc_money1="$line"
        elif [ "$linenum" == "17" ]; then
            acc_money2="$line"
        elif [ "$linenum" == "18" ]; then
            acc_money3="$line"
        elif [ "$linenum" == "19" ]; then
            acc_money4="$line"
        elif [ "$linenum" == "20" ]; then
            acc_vip="$line"
        elif [ "$linenum" == "21" ]; then
            acc_block_points="$line"
        elif [ "$linenum" == "22" ]; then
            acc_instagib_kills="$line"
        elif [ "$linenum" == "23" ]; then
            acc_instagib_wins="$line"
        elif [ "$linenum" == "24" ]; then
            acc_spawn_weapon0="$line"
        elif [ "$linenum" == "25" ]; then
            acc_spawn_weapon1="$line"
        elif [ "$linenum" == "26" ]; then
            acc_spawn_weapon2="$line"
        elif [ "$linenum" == "27" ]; then
            acc_ninjajetpack="$line"
        elif [ "$linenum" == "28" ]; then
            acc_last_playername="$line"
        elif [ "$linenum" == "29" ]; then
            acc_survival_deaths="$line"
        elif [ "$linenum" == "30" ]; then
            acc_instagib_deaths="$line"
        elif [ "$linenum" == "31" ]; then
            acc_taser_level="$line"
        elif [ "$linenum" == "32" ]; then
            acc_killingspree_record="$line"
        elif [ "$linenum" == "33" ]; then
            acc_euros="$line"
        elif [ "$linenum" == "34" ]; then
            acc_expiredate_vip="$line"
        elif [ "$linenum" == "35" ]; then
            acc_tele_rifle="$line"
        elif [ "$linenum" == "36" ]; then
            acc_expiredate_telerifle="$line"
        fi
        linenum="$((linenum+1))"
    done < "$account"
}

function fddr.print_account() {
    path="$1"
    fddr.parse_account "$path"
    echo "[ === '$acc_username' === ]"
    echo "essential:"
    echo "  file: $path"
    echo "  last playername: $acc_last_playername"
    echo "  password: $acc_password"
    echo "  port: $acc_port loggedin: $acc_logged_in"
    echo "  clientID: $acc_client_id disabled: $acc_disabled"
    echo "  euros: $acc_euros vip: $acc_vip vip-expire: $acc_expiredate_vip"
    echo "  telerifle: $acc_tele_rifle telerifle-expire: $acc_expiredate_telerifle"
    echo "stats:"
    echo "  level: $acc_level xp: $acc_xp"
    echo "  money: $acc_money police: $acc_police"
    echo "  $acc_money0"
    echo "  $acc_money1"
    echo "  $acc_money2"
    echo "  $acc_money3"
    echo "  $acc_money4"
    echo "  taserlevel: $acc_taser_level"
    echo "  spwanweapon0: $acc_spawn_weapon0"
    echo "  spwanweapon1: $acc_spawn_weapon1"
    echo "  spwanweapon2: $acc_spawn_weapon2"
    echo "  spooky ghost: $acc_spooky_ghost"
    echo "  ninjajetpack: $acc_ninjajetpack"
    echo "  kills: $acc_kills deaths: $acc_deaths"
    echo "  blockpoints: $acc_block_points spree: $acc_killingspree_record"
    echo "  survival k=$acc_survival_kills d=$acc_survival_deaths wins=$acc_survival_wins"
    echo "  insta k=$acc_instagib_kills d=$acc_instagib_deaths wins=$acc_instagib_wins"

}

function fddr.read_database() {
    :>"$FDDR_PURGE_FILE"
    if [ ! -d "$FDDR_ACC_PATH" ]
    then
        echo "Error: '$FDDR_ACC_PATH' is not a directory"
        exit 1
    fi
    for acc in "$FDDR_ACC_PATH"/*.acc
    do
        fddr.parse_account "$acc" || exit 1
        if [[ "$acc_money" == "0" ]] && [[ "$acc_xp" == "0" ]]
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
    done < "$FDDR_PURGE_FILE"
}

if [ "$#" == "0" ] || [ "$1" == "--help" ] || [ "$1" == "-h" ]
then
    echo "Usage: $(basename "$0") <account> [accounts path]"
    exit 0
elif [ "$2" != "" ]
then
    FDDR_ACC_PATH="$2"
fi

fddr.print_account "$FDDR_ACC_PATH/$1"

