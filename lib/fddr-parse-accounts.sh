#!/bin/bash
# F-DDrace accounts parser
# https://github.com/fokkonaut/F-DDrace/blob/79e3a5f49bd1efa59e34ffcbeb0cc62ee3fc8e0e/src/game/server/gamecontext.cpp#L4600-L4645

if [ ! -f lib/lib.sh ]
then
    echo "Error: lib/lib.sh not found!"
    echo "make sure you are in the root of the server repo"
    exit 1
fi

source lib/lib.sh

if [ "${BASH_VERSION::1}" -lt "4" ]
then
    err "Error: you need bash version 4 or later."
    exit 1
fi

if [ ! -f /usr/share/bash-completion/completions/fddr-parse-accounts.sh ]
then
	if [ -f ./lib/completions/fddr-parse-accounts.sh.bash.completion ]
	then
		log "installing bash completion ..."
		if [ "$UID" == "0" ]
		then
			cp \
				./lib/completions/fddr-parse-accounts.sh.bash.completion \
				/usr/share/bash-completion/completions/fddr-parse-accounts.sh
		elif [ -x "$(command -v sudo)" ]
		then
			sudo cp \
				./lib/completions/fddr-parse-accounts.sh.bash.completion \
				/usr/share/bash-completion/completions/fddr-parse-accounts.sh
		else
			wrn "missing permission to install completion"
		fi
	else
		wrn "bash completion not found"
	fi
fi

FDDR_PURGE_FILE="${FDDR_PURGE_FILE:-/tmp/fddr-purge.txt}"
FDDR_ACC_PATH="${FDDR_ACC_PATH:-./accounts}"
FDDR_NUM_LINES=45
FDDR_MIN_NAME_LEN=3
FDDR_MAX_NAME_LEN=20
FDDR_MIN_PW_LEN=3
FDDR_MAX_PW_LEN=128
FDDR_ACCFLAG_ZOOMCURSOR="$((1<<0))"
FDDR_ACCFLAG_PLOTSPAWN="$((1<<1))"

declare -A fddr_a_lines
declare -A fddr_a_names
fddr_warnings=0
fddr_cmd=error
arg_name=error
fddr_is_verbose=0
fddr_show_password=0

function fddr.reset_vars() {
	acc_port=""
	acc_logged_in="0"
	acc_disabled="0"
	acc_password=""
	acc_username=""
	acc_client_id="-1"
	acc_level="0"
	acc_xp="0"
	acc_money="0"
	acc_kills="0"
	acc_deaths="0"
	acc_police="0"
	acc_survival_kills="0"
	acc_survival_wins="0"
	acc_spooky_ghost="0"
	acc_money0=""
	acc_money1=""
	acc_money2=""
	acc_money3=""
	acc_money4=""
	acc_vip="0"
	acc_block_points="0"
	acc_instagib_kills="0"
	acc_instagib_wins="0"
	acc_spawn_weapon0="0"
	acc_spawn_weapon1="0"
	acc_spawn_weapon2="0"
	acc_ninjajetpack="0"
	acc_last_playername=""
	acc_survival_deaths="0"
	acc_instagib_deaths="0"
	acc_taser_level="0"
	acc_killingspree_record="0"
	acc_euros="0"
	acc_expiredate_vip="0"
	acc_portal_rifle="0"
	acc_expire_date_portal_rifle="0"
	acc_version=""
	acc_addr=""
	acc_last_addr=""
	acc_taser_battery="0"
	acc_contact=""
	acc_timeout_code=""
	acc_security_pin=""
	acc_register_date="0"
	acc_last_login_date="0"
	acc_flags="0"
	acc_email=""
}

function fddr.parse_account() {
	acc_path=$1
	if [ ! -f "$acc_path" ]
	then
		err "Error: file not found '$acc_path'"
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
			acc_portal_rifle="$line"
		elif [ "$linenum" == "36" ]; then
			acc_expire_date_portal_rifle="$line"
		elif [ "$linenum" == "37" ]; then
			acc_version="$line"
		elif [ "$linenum" == "38" ]; then
			acc_addr="$line"
		elif [ "$linenum" == "39" ]; then
			acc_last_addr="$line"
		elif [ "$linenum" == "40" ]; then
			acc_taser_battery="$line"
		elif [ "$linenum" == "41" ]; then
			acc_contact="$line"
		elif [ "$linenum" == "42" ]; then
			acc_timeout_code="$line"
		elif [ "$linenum" == "43" ]; then
			acc_security_pin="$line"
		elif [ "$linenum" == "44" ]; then
			acc_register_date="$line"
		elif [ "$linenum" == "45" ]; then
			acc_last_login_date="$line"
		elif [ "$linenum" == "46" ]; then
			acc_flags="$line"
		elif [ "$linenum" == "47" ]; then
			acc_email="$line"
		else
			err "Error: too many lines $linenum/$FDDR_NUM_LINES"
			err "       $acc_path"
			exit 1
		fi
	done < "$acc_path"
	if [ "$linenum" != "$FDDR_NUM_LINES" ]
	then
		if [ "$fddr_is_verbose" == "1" ]
		then
			wrn "Warning: invalid line number $linenum/$FDDR_NUM_LINES"
			wrn "       $acc_path"
		fi
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
        linenum="$((linenum+1))"; echo "$acc_portal_rifle"
        linenum="$((linenum+1))"; echo "$acc_expire_date_portal_rifle"
        linenum="$((linenum+1))"; echo "$acc_version"
        linenum="$((linenum+1))"; echo "$acc_addr"
        linenum="$((linenum+1))"; echo "$acc_last_addr"
        linenum="$((linenum+1))"; echo "$acc_taser_battery"
        linenum="$((linenum+1))"; echo "$acc_contact"
        linenum="$((linenum+1))"; echo "$acc_timeout_code"
        linenum="$((linenum+1))"; echo "$acc_security_pin"
        linenum="$((linenum+1))"; echo "$acc_register_date"
        linenum="$((linenum+1))"; echo "$acc_last_login_date"
        linenum="$((linenum+1))"; echo "$acc_flags"
        linenum="$((linenum+1))"; echo "$acc_email"
    } > "$file_path"
    if [ "$linenum" != "$FDDR_NUM_LINES" ]
    then
        err "Error: invalid line number $linenum/$FDDR_NUM_LINES"
        exit 1
    fi
}

function fddr.print_timestamp() {
	local ts="$1"
	if [ "$ts" == "" ] || [ "$ts" == "0" ]
	then
		printf "%s" "$ts"
		return
	fi
	printf "%s (%s)" "$ts" "$(date -d @"$ts")"
}

function fddr.print_account() {
	path="$1"
	fddr.parse_account "$path"
	echo "[ === '$acc_username' === ]"
	echo "essential:"
	echo "  file: $path"
	echo "  last playername: $acc_last_playername"
	if [ "$fddr_show_password" == "1" ]
	then
		echo "  password: $acc_password"
	else
		echo "  password: **"
	fi
	echo "  pin: $acc_security_pin"
	echo "  port: $acc_port loggedin: $acc_logged_in"
	echo "  clientID: $acc_client_id disabled: $acc_disabled"
	echo "  euros: $acc_euros vip: $acc_vip vip-expire: $(fddr.print_timestamp "$acc_expiredate_vip")"
	echo "  portalrifle: $acc_portal_rifle portal-rifle-expire: $(fddr.print_timestamp "$acc_expire_date_portal_rifle")"
	echo "meta:"
	echo "  version: $acc_version"
	echo "  addr: $acc_addr last addr: $acc_last_addr"
	echo "  register date: $(fddr.print_timestamp "$acc_register_date")"
	echo "  last login date: $(fddr.print_timestamp "$acc_last_login_date")"
	echo "  contact: $acc_contact"
	echo "  email: $acc_email"
	echo -n "  flags: $acc_flags"
	if [[ "$((FDDR_ACCFLAG_PLOTSPAWN & acc_flags))" == "1" ]]
	then
		echo -n " PLOTSPAWN"
	fi
	if [[ "$((FDDR_ACCFLAG_ZOOMCURSOR & acc_flags))" == "1" ]]
	then
		echo -n " ZOOMCURSOR"
	fi
	echo ""
	echo "  timoutcode: $acc_timeout_code"
	echo "stats:"
	echo "  level: $acc_level xp: $acc_xp"
	echo "  money: $acc_money police: $acc_police"
	echo "  $acc_money0"
	echo "  $acc_money1"
	echo "  $acc_money2"
	echo "  $acc_money3"
	echo "  $acc_money4"
	echo "  taserlevel: $acc_taser_level"
	echo "  tasterbattery: $acc_taser_battery"
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

function fddr.get_var() {
    local path="$1"
    local var="$2"
    fddr.parse_account "$path"
    eval "echo \$$var"
}

function fddr.get_vars() {
    fddr.reset_vars
    # TODO: remove shellcheck magic comment when github actions updated
    # shellcheck disable=SC2154
    for var in "${!acc_@}"
    do
        echo "$var"
    done
}

function fddr.check_database() {
    if [ ! -d "$FDDR_ACC_PATH" ]
    then
        err "Error: '$FDDR_ACC_PATH' is not a directory"
        exit 1
    fi
    for acc in "$FDDR_ACC_PATH"/*.acc
    do
        fddr.parse_account "$acc" || exit 1
        # values
        if ! [[ "$acc_port" =~ ^[0-9]*$ ]]
        then
            wrn "Invalid port '$acc_port' $(basename "$acc_path")"
            fddr_warnings="$((fddr_warnings+1))"
        fi
        if ! [[ "$acc_logged_in" =~ ^(0|1)$ ]]
        then
            wrn "Invalid logged in '$acc_logged_in' $(basename "$acc_path")"
            fddr_warnings="$((fddr_warnings+1))"
        fi
        if ! [[ "$acc_disabled" =~ ^(0|1)$ ]]
        then
            wrn "Invalid disables '$acc_disabled' $(basename "$acc_path")"
            fddr_warnings="$((fddr_warnings+1))"
        fi
        if [[ "${#acc_password}" -lt "$FDDR_MIN_PW_LEN" ]]
        then
            wrn "Password too short ${#acc_password}/$FDDR_MIN_PW_LEN $(basename "$acc_path")"
            fddr_warnings="$((fddr_warnings+1))"
        fi
        if [[ "${#acc_password}" -gt "$FDDR_MAX_PW_LEN" ]]
        then
            wrn "Password too long ${#acc_password}/$FDDR_MAX_PW_LEN $(basename "$acc_path")"
            fddr_warnings="$((fddr_warnings+1))"
        fi
        if [[ "${#acc_username}" -lt "$FDDR_MIN_NAME_LEN" ]]
        then
            wrn "Username too short ${#acc_username}/$FDDR_MIN_NAME_LEN $(basename "$acc_path")"
            fddr_warnings="$((fddr_warnings+1))"
        fi
        if [[ "${#acc_username}" -gt "$FDDR_MAX_NAME_LEN" ]]
        then
            wrn "Username too long ${#acc_username}/$FDDR_MAX_NAME_LEN $(basename "$acc_path")"
            fddr_warnings="$((fddr_warnings+1))"
        fi
        if ! [[ "${acc_client_id}" =~ ^(-)?[0-9]{1,2}$ ]]
        then
            wrn "Invalid client id '$acc_client_id' $(basename "$acc_path")"
            fddr_warnings="$((fddr_warnings+1))"
        fi
        if [[ ! "${acc_security_pin}" =~ ^[0-9]{4}$ ]] && [[ "$acc_security_pin" != "" ]]
        then
            wrn "Invalid security pin '$acc_security_pin' $(basename "$acc_path")"
            fddr_warnings="$((fddr_warnings+1))"
        fi
	# dates are unix epoche so the length of 10 will become invalid Saturday, November 20, 2286 5:46:40 PM
	# in case someone wonders in 265 years why this breaks... just replace {10} with {10,11} :D
        if [[ ! "${acc_register_date}" =~ ^[0-9]{10}$ ]] && [[ "${acc_register_date}" != "0" ]]
        then
            wrn "Invalid register date '$acc_register_date' $(basename "$acc_path")"
            fddr_warnings="$((fddr_warnings+1))"
        fi
        if [[ ! "${acc_last_login_date}" =~ ^[0-9]{10}$ ]] && [[ "${acc_last_login_date}" != "0" ]]
        then
            wrn "Invalid last login date '$acc_last_login_date' $(basename "$acc_path")"
            fddr_warnings="$((fddr_warnings+1))"
        fi
        if [[ ! "${acc_flags}" =~ ^-?[0-9]+$ ]]
        then
            wrn "Invalid flags '$acc_flags' $(basename "$acc_path")"
            fddr_warnings="$((fddr_warnings+1))"
        fi
        if [[ ! "${acc_email}" =~ ^[a-zA-Z0-9.\-@]+$ ]] && [[ "$acc_email" != "" ]]
        then
            wrn "Invalid email '$acc_email' $(basename "$acc_path")"
            fddr_warnings="$((fddr_warnings+1))"
        fi
        # lines
        fddr_a_lines[$linenum]="$((fddr_a_lines[$linenum]+1))"
        if [ "${fddr_a_lines[$linenum]}" -gt "1" ]
        then
            fddr_a_names[$linenum]="${fddr_a_names[$linenum]}, "
        fi
        fddr_a_names[$linenum]="${fddr_a_names[$linenum]}$(basename "$acc_path")"
    done
    echo -e "lines\\t\\tcount\\t\\tnames\\n"
    local k
    local trim_names
    local w
    local i
    w="$(tput cols)"
    w="$((w-32))" # first to cols
    for k in "${!fddr_a_lines[@]}";
    do
        for ((i=1;i<16;i++))
        do
            trim_names="$(echo "${fddr_a_names[$k]}" | cut -d ',' "-f1-$i")"
            if [ "${#trim_names}" -gt "$w" ]
            then
                i="$((i-1))"
                trim_names="$(echo "${fddr_a_names[$k]}" | cut -d ',' "-f1-$i")"
                break
            fi
        done
        echo -e "$k\\t\\t${fddr_a_lines[$k]}\\t\\t$trim_names"
    done
}

function fddr.show_vars() {
    local acc="$1"
    local variables="$2"
    local var
    fddr.parse_account "$acc" || exit 1
    for var in $variables
    do
        if [ "$var" == "acc" ]
        then
            echo "$acc"
        else
            eval "echo \$$var"
        fi
    done
}

function fddr.filter_print() {
    local acc="$1"
    local vars="$2"
    if [ "$vars" == "" ]
    then
        echo "$acc"
    else
        fddr.show_vars "$acc" "$vars"
    fi
}

function fddr.filter() {
    # usage: fddr.filter variable operator value
    # variables: (see get_vars)
    # operator: == != < >
    # value: string or integer
    local acc
    local num_accs=0
    local num_matches=0
    local filter_variable="$1"
    local filter_operator="$2"
    local filter_value="$3"
    local arg_show="$4"
    local val
    local var
    local found=0
    if { [ "$1" == "--help" ] || [ "$1" == "help" ] || [ "$1" == "-h" ]; } || \
        { [ "$1" == "" ] && [ "$2" == "" ] && [ "$3" == "" ]; }
    then
        err "usage: $0 filter 'variable operator value' ['show variables..']"
        err "example:"
        err "  $0 filter 'acc_level > 60'"
        err "  $0 filter 'acc_level > 60' 'show acc acc_username acc_level"
        exit 1
    elif [ "$filter_variable" == "" ]
    then
        err "filter: variable can not be empty!"
        err "        see $(tput bold)$0 get_vars$(tput sgr0) for a full list"
        exit 1
    elif [[ ! "$filter_operator" =~ (==|!=|<|>) ]]
    then
        err "filter: invalid operator '$filter_operator'"
        err "        valid operators: ==, !=, <, and >"
        exit 1
    elif [[ "$filter_operator" =~ (<|>) ]] && [ "$filter_value" == "" ]
    then
        err "filter: value can not be empty when using operator '$filter_operator'"
        exit 1
    fi
    fddr.reset_vars
    for var in "${!acc_@}"
    do
        if [ "$filter_variable" == "$var" ]
        then
            found=1
            break
        fi
    done
    if [ "$found" != "1" ]
    then
        err "filter: invalid variable '$filter_variable'"
        err "        $0 get_vars"
        exit 1
    fi
    if [ ! -d "$FDDR_ACC_PATH" ]
    then
        err "Error: '$FDDR_ACC_PATH' is not a directory"
        exit 1
    fi
    for acc in "$FDDR_ACC_PATH"/*.acc
    do
        num_accs="$((num_accs+1))"
        fddr.parse_account "$acc" || exit 1
        val="$(eval "echo \$$filter_variable")"
        if [ "$filter_operator" == "==" ]
        then
            if [ "$val" == "$filter_value" ]
            then
                num_matches="$((num_matches+1))"
                fddr.filter_print "$acc" "$arg_show"
            fi
        elif [ "$filter_operator" == "!=" ]
        then
            if [ "$val" != "$filter_value" ]
            then
                num_matches="$((num_matches+1))"
                fddr.filter_print "$acc" "$arg_show"
            fi
        elif [ "$filter_operator" == ">" ]
        then
            if [ "$val" -gt "$filter_value" ]
            then
                num_matches="$((num_matches+1))"
                fddr.filter_print "$acc" "$arg_show"
            fi
        elif [ "$filter_operator" == "<" ]
        then
            if [ "$val" -lt "$filter_value" ]
            then
                num_matches="$((num_matches+1))"
                fddr.filter_print "$acc" "$arg_show"
            fi
        else
            err "invalid operator '$filter_operator'"
            exit 1
        fi
    done
    log "total accounts: $num_accs matches: $num_matches"
}

function fddr.rewrite_database() {
    if [ ! -d "$FDDR_ACC_PATH" ]
    then
        err "Error: '$FDDR_ACC_PATH' is not a directory"
        exit 1
    fi
    for acc in "$FDDR_ACC_PATH"/*.acc
    do
        fddr.parse_account "$acc" || exit 1
        fddr.write_account "$acc"
    done
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
    tput bold
    printf "Usage: "
    tput sgr0
    echo "$(basename "$0") [Flags..] <CMD> [args..] [accounts path]"
    tput bold
    echo "Flags:"
    tput sgr0
    echo "  -v - verbose"
    echo "  -p - password"
    tput bold
    echo "CMD:"
    tput sgr0
    echo "  show <account>"
    echo "  show_vars <account> <var..>"
    echo "  parse"
    echo "  rewrite"
    echo "  check"
    echo "  get_var <var> <account..>"
    echo "  get_vars"
    echo "  filter 'variable operator value' ['show <var..>']"
    tput bold
    echo "ENV:"
    tput sgr0
    echo "  FDDR_ACC_PATH   path to accounts directory (default ./accounts)"
    tput bold
    echo "EXAMPLES:"
    tput sgr0
    echo "  $0 show ChillerDragon.acc"
    echo "  $0 -v show ChillerDragon.acc ../accounts"
    echo "  $0 parse ../accounts"
    echo "  $0 filter 'acc_level > 100'"
    echo "  $0 filter 'acc_level > 100' 'show acc acc_level acc_xp'"
    echo "  $0 filter 'acc_contact != \"\"' 'show acc_contact'"
    echo "  FDDR_ACC_PATH=~/data/accounts $(basename "$0") show ChillerDragon.acc"
    echo "  find \"\$FDDR_ACC_PATH\" -print0 | xargs -0 ./lib/fddr-parse-accounts.sh get_var acc_contact | awk 'NF'"
    exit 0
fi

for arg in "$@"
do
    if [ "$arg" == "-v" ] || [ "$arg" == "--verbose" ]
    then
        shift
        fddr_is_verbose=1
    elif [ "$arg" == "-p" ] || [ "$arg" == "--password" ]
    then
        shift
        fddr_show_password=1
    fi
done

if [ "$1" == "show" ]
then
    shift
    fddr_cmd=show
    if [ "$1" == "" ]
    then
        echo "Usage: $(basename "$0") show <account>"
        exit 1
    fi
    arg_name="$(basename "$1")"
    shift
elif [ "$1" == "show_vars" ]
then
	shift
	fddr_cmd=show_vars
	if [ "$1" == "" ]
	then
		echo "Usage: $(basename "$0") show_vars <account> <var..>"
		exit 1
	fi
	arg_name="$(basename "$1")"
	shift
	arg_vars=''
	while [ "$#" -gt "1" ]
	do
		arg_vars+="$1 "
		shift
	done
	arg_vars+="$1"
	shift
elif [ "$1" == "parse" ]
then
    shift
    fddr_cmd=parse
elif [ "$1" == "rewrite" ]
then
    shift
    fddr_cmd=rewrite
    wrn "WARNING THIS CHANGES ACCOUNT DATA"
    wrn "MAKE SURE THE SERVER IS NOT RUNNING"
    wrn "MAKE SURE YOU KOWN WHAT YOU ARE DOING"
    wrn "do you really want to rewrite? [y/N]"
    read -r -n 1 yn
    echo ""
    if ! [[ "$yn" =~ [yY] ]]
    then
        log "stopping..."
        exit
    fi
    wrn "rewriting '$FDDR_ACC_PATH'"
    wrn "do you have a backup of this directory? [y/N]"
    read -r -n 1 yn
    echo ""
    if ! [[ "$yn" =~ [yY] ]]
    then
        log "stopping..."
        exit
    fi
    wrn "really? [y/N]"
    read -r -n 1 yn
    echo ""
    if ! [[ "$yn" =~ [yY] ]]
    then
        log "stopping..."
        exit
    fi
    wrn "Stop lying I know you have no backups..."
    wrn "But I can copy your accs to /tmp/xxx_fddr_accbackup"
    wrn "do you want me to create a backup? [y/N]"
    read -r -n 1 yn
    echo ""
    if [[ "$yn" =~ [yY] ]]
    then
        log "writing backup to /tmp/xxx_fddr_accbackup ..."
        cp -r "$FDDR_ACC_PATH" /tmp/xxx_fddr_accbackup
    fi
elif [ "$1" == "check" ]
then
    shift
    fddr_cmd=check
elif [ "$1" == "get_var" ]
then
    shift
    fddr_cmd=get_var
    if [ "$1" == "" ]
    then
        echo "Usage: $(basename "$0") get_var <var> <account>"
        exit 1
    fi
    arg_var="$1"
    shift
    if [ "$1" == "" ]
    then
        echo "Usage: $(basename "$0") get_var <var> <account>"
        exit 1
    fi
    arg_names=()
    for arg in "$@"
    do
        if [[ "$arg" =~ \.acc$ ]]
        then
            arg_names+=("$(basename "$1")")
            shift
        else
            break
        fi
    done
elif [ "$1" == "get_vars" ]
then
    shift
    fddr_cmd=get_vars
elif [ "$1" == "filter" ]
then
    shift
    fddr_cmd=filter
    arg_filter="$1"
    shift
    arg_variable="$(echo "$arg_filter" | awk '{ print $1 }')"
    arg_operator="$(echo "$arg_filter" | awk '{ print $2 }')"
    arg_value="$(echo "$arg_filter" | awk '{ print $3 }')"
    if [ "${arg_value::1}" == '"' ]
    then
        arg_value="$(echo "$arg_filter" | cut -d'"' -f2)"
    elif [ "${arg_value::1}" == "'" ]
    then
        arg_value="$(echo "$arg_filter" | cut -d"'" -f2)"
    fi
    if [[ "$1" =~ show\  ]]
    then
        arg_show="$1"
        arg_show="${arg_show:5}" # cut off 'show '
        shift
    fi
else
    echo "Error: invalid cmd '$1'"
    exit 1
fi

if [ "$1" != "" ]
then
    FDDR_ACC_PATH="$1"
fi

if [ "$fddr_cmd" == "show" ]
then
    fddr.print_account "$FDDR_ACC_PATH/$arg_name"
elif [ "$fddr_cmd" == "show_vars" ]
then
    fddr.show_vars "$FDDR_ACC_PATH/$arg_name" "$arg_vars"
elif [ "$fddr_cmd" == "parse" ]
then
    fddr.read_database
elif [ "$fddr_cmd" == "rewrite" ]
then
    log "rewriting database ..."
    fddr.rewrite_database
elif [ "$fddr_cmd" == "check" ]
then
    fddr.check_database
elif [ "$fddr_cmd" == "get_var" ]
then
    for name in "${arg_names[@]}"
    do
        fddr.get_var "$FDDR_ACC_PATH/$name" "$arg_var"
    done
elif [ "$fddr_cmd" == "get_vars" ]
then
    fddr.get_vars
elif [ "$fddr_cmd" == "filter" ]
then
    fddr.filter "$arg_variable" "$arg_operator" "$arg_value" "$arg_show"
fi

if [ "$fddr_warnings" != "0" ] && [ "$fddr_is_verbose" == "1" ]
then
    wrn "finished with $fddr_warnings warnings."
fi

