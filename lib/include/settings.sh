#!/bin/bash
shopt -s extglob # used for trailing slashes globbing

# init variables
aSettingsFiles=()
current_settings_file="server.cnf"
line_num=0
aSettStr=()
aSettVal=()
aSettValid=()

function load_settings() {
	local init="$1"
	local settings_file="$2"
	local cfg_upper
	local cfg_lower
	local default_value
	local validation
	local index=0
	while read -r line
	do
		if [[ "$line" =~ [[:space:]]*# ]]
		then
			continue
		fi
		if [[ "$(echo "$line" | xargs)" == "" ]]
		then
			continue
		fi
		cfg_upper="$(echo "$line" | awk -F',' '{ print $1 }')"
		cfg_upper="${cfg_upper:1:-1}"
		cfg_lower="$(echo "$line" | awk -F',' '{ print $2 }')"
		cfg_lower="${cfg_lower:2:-1}"
		default_value="$(echo "$line" | awk -F',' '{ print $3 }')"
		default_value="${default_value:2:-1}"
		validation="$(echo "$line" | awk -F',' '{ print $4 }')"
		validation="${validation:2:-1}"
		if [ "$init" == "1" ]
		then
			if [ "$cfg_upper" == "CFG_CMAKE_FLAGS" ]
			then
				eval "read -r -a $cfg_upper <<< \"$default_value\""
				eval "export $cfg_upper"
			else
				eval "export $cfg_upper=\"$default_value\""
			fi
			# echo "upper=$cfg_upper lower=$cfg_lower default=$default_value validation=$validation"
			aSettStr+=("$cfg_lower")
			aSettVal+=("$default_value")
			aSettValid+=("$allowed_pattern")
		else
			if [ "$cfg_upper" == "CFG_CMAKE_FLAGS" ]
			then
				eval "read -r -a $cfg_upper <<< \"${aSettVal[$index]}\""
				eval "export $cfg_upper"
			else
				eval "export $cfg_upper=\"${aSettVal[$index]}\""
			fi
		fi
		index="$((index+1))"
	done < "$settings_file"
}

function create_settings() {
    if [ -f $current_settings_file ];
    then
        return
    fi
    local i
    log "FileError: '$current_settings_file' not found"
    read -p "Do you want to create one? [y/N]" -n 1 -r
    echo 
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        {
            echo "# DDNet++ server config by ChillerDragon"
            echo "# https://github.com/DDNetPP/server"
            for i in "${!aSettStr[@]}"
            do
                echo "${aSettStr[$i]}=${aSettVal[$i]}"
            done
        } > "$current_settings_file"
        edit_file "$current_settings_file"
    fi
    exit 1
}

function settings_err() {
    err "SettingsError: $(tput bold)$current_settings_file:$line_num$(tput sgr0) $1"
}

function settings_err_tab() {
    err "               $1"
}

function parse_settings_line() {
        local sett=$1
        local val=$2
        if [ "$sett" == "compiled_binary_name" ]
        then
            wrn "WARNING: 'compiled_binary_name' is deprecated by 'compiled_teeworlds_name'"
            wrn "         please fix at $current_settings_file:$line_num"
            sett=compiled_teeworlds_name
        elif [ "$sett" == "gitpath_src" ]
        then
            wrn "WARNING: 'gitpath_src' is deprecated by 'git_root'"
            wrn "         please fix at $current_settings_file:$line_num"
            sett=git_root
        fi
        local i
        for i in "${!aSettStr[@]}"
        do
            if  [ "$sett" == "${aSettStr[$i]}" ]
            then
                # printf "[setting] (%s)%-16s=  %s\\n" "$i" "$sett" "$val"
                if [[ "${aSettStr[$i]}" =~ path ]]
                then
                    val="${val%%+(/)}" # strip trailing slash
                fi
                valid_pattern=${aSettValid[$i]}
                if [[ "$valid_pattern" != "" ]] && [[ ! "$val" =~ $valid_pattern ]]
                then
                    settings_err "invalid value '$val' for setting '$sett'"
                    err "               values have to match $valid_pattern"
                    exit 1
                fi
                aSettVal[$i]="$val"
                return
            fi
        done
        settings_err "unkown setting '$(tput bold)$sett$(tput sgr0)'"
        exit 1
}

function parse_settings_cmd() {
    local cmd="$1"
    shift
    if [ "$cmd" == "include" ]
    then
        if [ ! -f "$1" ]
        then
            settings_err "include command failed"
            settings_err_tab "no such file $(tput bold)$1$(tput sgr0)"
            exit 1
        fi
        read_settings_file "$1"
    elif [ "$cmd" == "echo" ]
    then
        echo "$(tput bold)[settings]$(tput sgr0) $*"
    else
        settings_err "unkown command '$(tput bold)$cmd$(tput sgr0)'"
        exit 1
    fi
}

function read_settings_file() {
    local filename="$1"
    current_settings_file="$filename"
    line_num=0
    local i
    local split_line
    local cmd_and_args
    for i in "${aSettingsFiles[@]}"
    do
        if [ "$i" == "$filename" ]
        then
            settings_err "trying to include $filename recursively"
            exit 1
        fi
    done
    aSettingsFiles+=("$filename")
    while read -r line
    do
        line_num="$((line_num + 1))"
        if [ "${line:0:1}" == "#" ]
        then
            continue # ignore comments
        elif [ -z "$line" ]
        then
            continue # ignore empty lines
        fi
        local line_set=""
        local line_val=""
        if ! echo "$line"| grep -q '='
        then
            IFS=' ' read -ra cmd_and_args <<< "$line"
            parse_settings_cmd "${cmd_and_args[@]}"
            continue
        fi
        IFS='=' read -ra split_line <<< "$line"
        for i in "${!split_line[@]}"
        do
            # split by '=' and then join all the elements bigger than 0
            # thus we allow using '=' inside the value
            if [ "$i" == "0" ]
            then
                line_set="${split_line[$i]}"
            else
                if [ "$i" -gt "1" ]
                then
                    line_val+="="
                fi
                line_val+="${split_line[$i]}"
            fi
        done
        parse_settings_line "$line_set" "$line_val"
    done < "$filename"
}

function is_cfg() {
    # check if cfg is truthy
    # does not take a cfg value but a var name
    # example: is_cfg CFG_GDB_DUMP_CORE
    local cfg
    cfg=$1
    case "${!cfg}" in
        1|true) return 0;;
        yes|on) return 0;;
        *) return 1;;
    esac
    return 1
}

# load syntax
load_settings 1 ./lib/include/settings.txt
for plugin in ./lib/plugins/*/
do
	[ -d "$plugin" ] || continue

	load_settings 1 "$plugin"settings.txt
done

# load user configs
create_settings # create fresh if null
read_settings_file "$current_settings_file" # get values from file
load_settings 0 ./lib/include/settings.txt # save values to env vars
for plugin in ./lib/plugins/*/
do
	[ -d "$plugin" ] || continue

	load_settings 0 "$plugin"settings.txt
done

if [ "$CFG_SERVER_TYPE" == "tem" ]
then
    tem_settings_path="$CFG_TEM_PATH/$CFG_TEM_SETTINGS"
    if [ ! -f "$tem_settings_path" ]
    then
        err "ERROR: tem settings file not found"
        err "       $tem_settings_path"
        exit 1
    fi
    CFG_LOGS_PATH="$(grep '^sh_logs_path' "$tem_settings_path" | tail -n1 | cut -d'=' -f2-)"
    if [ "${CFG_LOGS_PATH::1}" != "/" ]
    then
        CFG_LOGS_PATH="$HOME/.teeworlds/dumps/$CFG_LOGS_PATH"
    fi
fi
CFG_LOGS_PATH="${CFG_LOGS_PATH%%+(/)}" # strip trailing slash
LOGS_PATH_TW="$CFG_LOGS_PATH"
IS_DUMPS_LOGPATH=0

if [ "$CFG_LOGS_PATH" == "" ]
then
    err "[setting] gitpath_log can not be empty"
    exit 1
fi

if [[ $CFG_LOGS_PATH =~ \.teeworlds/dumps/ ]]
then
    # log "detected 0.7 logpath"
    # only use the relative part starting from dumps dir
    LOGS_PATH_TW="${CFG_LOGS_PATH##*.teeworlds/dumps/}"
    IS_DUMPS_LOGPATH=1
    if [ "$LOGS_PATH_TW" == "" ]
    then
        wrn "WARNING log root path is empty"
        read -p "Do you want to proceed? [y/N]" -n 1 -r
        echo ""
        if ! [[ $REPLY =~ ^[Yy]$ ]]
        then
            log "aborting ..."
            exit 1
        fi
    fi
fi
LOGS_PATH_FULL="$CFG_LOGS_PATH/$CFG_SRV_NAME/logs"
LOGS_PATH_FULL_TW="$LOGS_PATH_TW/$CFG_SRV_NAME/logs"
if [ "$CFG_SERVER_TYPE" == "tem" ]
then
    LOGS_PATH_FULL="$CFG_LOGS_PATH"
    LOGS_PATH_FULL_TW="$LOGS_PATH_TW"
fi

export CFG_CMAKE_FLAGS # usage: "${CFG_CMAKE_FLAGS[@]}"
export IS_DUMPS_LOGPATH
export LOGS_PATH_TW
export LOGS_PATH_FULL
export LOGS_PATH_FULL_TW
export CFG_BIN=bin/$CFG_SRV_NAME
if [[ "${CFG_CMAKE_FLAGS,,}" =~ debug ]]
then
    export CFG_DEBUG=1
    export CFG_BIN="${CFG_BIN}_d"
else
    export CFG_DEBUG=0
fi

