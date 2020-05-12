#!/bin/bash
# F-DDrace accounts parser
# https://github.com/fokkonaut/F-DDrace/blob/3a41550df2502ca304d79465706e6fd52b951b5f/src/game/server/gamecontext.cpp#L3826-L3862

if [ ! -f lib/lib.sh ]
then
    echo "Error: lib/lib.sh not found!"
    echo "make sure you are in the root of the server repo"
    exit 1
fi

source lib/lib.sh

FDDR_PURGE_FILE=/tmp/fddr-purge.txt
FDDR_ACC_PATH=./accounts
FDDR_NUM_LINES=36

fddr_warnings=0

function fddr.reset_vars() {
    acc_port=""
    acc_logged_in=""
    acc_disabled=""
    acc_password=""
    acc_username=""
    acc_client_id=""
    acc_level=""
    acc_xp=""
    acc_money=""
    acc_kills=""
    acc_deaths=""
    acc_police=""
    acc_survival_kills=""
    acc_survival_wins=""
    acc_spooky_ghost=""
    acc_money0=""
    acc_money1=""
    acc_money2=""
    acc_money3=""
    acc_money4=""
    acc_vip=""
    acc_block_points=""
    acc_instagib_kills=""
    acc_instagib_wins=""
    acc_spawn_weapon0=""
    acc_spawn_weapon1=""
    acc_spawn_weapon2=""
    acc_ninjajetpack=""
    acc_last_playername=""
    acc_survival_deaths=""
    acc_instagib_deaths=""
    acc_taser_level=""
    acc_killingspree_record=""
    acc_euros=""
    acc_expiredate_vip=""
    acc_tele_rifle=""
    acc_expiredate_telerifle=""
}

function fddr.parse_account() {
    account=$1
    if [ ! -f "$account" ]
    then
        err "Error: file not found '$account'"
        exit 1
    fi
    fddr.reset_vars
    linenum=-1
    while IFS= read -r line
    do
        linenum="$((linenum+1))"
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
        else
            err "Error: too many lines $linenum/$FDDR_NUM_LINES"
            err "       $account"
            exit 1
        fi
    done < "$account"
    if [ "$linenum" != "$FDDR_NUM_LINES" ]
    then
        wrn "Warning: invalid line number $linenum/$FDDR_NUM_LINES"
        wrn "       $account"
        fddr_warnings="$((fddr_warnings+1))"
    fi
}

function fddr.write_account() {
    local file_path
    file_path="$1"
    if [ "$file_path" == "" ]
    then
        err "Error: file path can not be empty"
        exit 1
    elif ! [[ "$file_path" =~ \.acc$ ]]
    then
        err "Error: account file has to end in .acc"
        exit 1
    fi
    exit 0
    {
        linenum=-1
        linenum="$((linenum+1))"; echo "$acc_port"
        linenum="$((linenum+1))"; echo "$acc_logged_in"
        linenum="$((linenum+1))"; echo "$acc_disabled"
        linenum="$((linenum+1))"; echo "$acc_password"
        linenum="$((linenum+1))"; echo "$acc_username"
        linenum="$((linenum+1))"; echo "$acc_client_id"
        linenum="$((linenum+1))"; echo "$acc_level"
        linenum="$((linenum+1))"; echo "$acc_xp"
        linenum="$((linenum+1))"; echo "$acc_money"
        linenum="$((linenum+1))"; echo "$acc_kills"
        linenum="$((linenum+1))"; echo "$acc_deaths"
        linenum="$((linenum+1))"; echo "$acc_police"
        linenum="$((linenum+1))"; echo "$acc_survival_kills"
        linenum="$((linenum+1))"; echo "$acc_survival_wins"
        linenum="$((linenum+1))"; echo "$acc_spooky_ghost"
        linenum="$((linenum+1))"; echo "$acc_money0"
        linenum="$((linenum+1))"; echo "$acc_money1"
        linenum="$((linenum+1))"; echo "$acc_money2"
        linenum="$((linenum+1))"; echo "$acc_money3"
        linenum="$((linenum+1))"; echo "$acc_money4"
        linenum="$((linenum+1))"; echo "$acc_vip"
        linenum="$((linenum+1))"; echo "$acc_block_points"
        linenum="$((linenum+1))"; echo "$acc_instagib_kills"
        linenum="$((linenum+1))"; echo "$acc_instagib_wins"
        linenum="$((linenum+1))"; echo "$acc_spawn_weapon0"
        linenum="$((linenum+1))"; echo "$acc_spawn_weapon1"
        linenum="$((linenum+1))"; echo "$acc_spawn_weapon2"
        linenum="$((linenum+1))"; echo "$acc_ninjajetpack"
        linenum="$((linenum+1))"; echo "$acc_last_playername"
        linenum="$((linenum+1))"; echo "$acc_survival_deaths"
        linenum="$((linenum+1))"; echo "$acc_instagib_deaths"
        linenum="$((linenum+1))"; echo "$acc_taser_level"
        linenum="$((linenum+1))"; echo "$acc_killingspree_record"
        linenum="$((linenum+1))"; echo "$acc_euros"
        linenum="$((linenum+1))"; echo "$acc_expiredate_vip"
        linenum="$((linenum+1))"; echo "$acc_tele_rifle"
        linenum="$((linenum+1))"; echo "$acc_expiredate_telerifle"
    } > "$file_path"
    if [ "$linenum" != "$FDDR_NUM_LINES" ]
    then
        err "Error: invalid line number $linenum/$FDDR_NUM_LINES"
        exit 1
    fi
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
        err "Error: '$FDDR_ACC_PATH' is not a directory"
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

if [ "$fddr_warnings" != "0" ]
then
    wrn "finished with $fddr_warnings warnings."
fi

