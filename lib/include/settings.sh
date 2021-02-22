#!/bin/bash
shopt -s extglob # used for trailing slashes globbing

# init variables
aSettingsFiles=()
current_settings_file="server.cnf"
line_num=0
aSettStr=();aSettVal=();aSettValid=()
aSettStr+=("git_root");aSettVal+=("/home/$USER/git");aSettValid+=('')
aSettStr+=("gitpath_mod");aSettVal+=("/home/$USER/git/mod");aSettValid+=('')
aSettStr+=("gitpath_bot");aSettVal+=("/home/$USER/git/chillerbot-h7");aSettValid+=('')
aSettStr+=("gitpath_log");aSettVal+=("/home/$USER/.teeworlds/dumps/TeeworldsLogs");aSettValid+=('')
aSettStr+=("server_name");aSettVal+=("teeworlds");aSettValid+=('')
aSettStr+=("compiled_teeworlds_name");aSettVal+=("teeworlds_srv");aSettValid+=('')
aSettStr+=("compiled_bot_name");aSettVal+=("chillerbot-z7");aSettValid+=('')
aSettStr+=("cmake_flags");aSettVal+=("-DCMAKE_BUILD_TYPE=Debug");aSettValid+=('')
aSettStr+=("error_logs");aSettVal+=("1");aSettValid+=('')
# aSettStr+=("error_logs_api");aSettVal+=("curl -d \"{\\\"err\\\":\\\"\$err\\\"}\" -H 'Content-Type: application/json' http://localhost:80/api")
aSettStr+=("error_logs_api");aSettVal+=("test");aSettValid+=('')
aSettStr+=("editor");aSettVal+=("");aSettValid+=('')
aSettStr+=("gdb_cmds");aSettVal+=("");aSettValid+=('')
aSettStr+=("gdb_dump_core");aSettVal+=("0");aSettValid+=('')
# aSettStr+=("is_debug");aSettVal+=("1");aSettValid+=('')
aSettStr+=("cstd");aSettVal+=("0");aSettValid+=('')
aSettStr+=("post_logs_dir");aSettVal+=("");aSettValid+=('')
aSettStr+=("git_force_pull");aSettVal+=("0");aSettValid+=('')
aSettStr+=("test_run");aSettVal+=("0");aSettValid+=('')
aSettStr+=("test_run_port");aSettVal+=("8303");aSettValid+=('')
aSettStr+=("git_commit");aSettVal+=("");aSettValid+=('')
aSettStr+=("git_branch");aSettVal+=("");aSettValid+=('')
aSettStr+=("server_type");aSettVal+=("teeworlds");aSettValid+=('(tem|teeworlds)')
aSettStr+=("tem_settings");aSettVal+=("tem.settings");aSettValid+=('')
aSettStr+=("tem_path");aSettVal+=("/home/$USER/git/TeeworldsEconMod");aSettValid+=('')
aSettStr+=("env_build");aSettVal+=("");aSettValid+=('')
aSettStr+=("env_runtime");aSettVal+=("");aSettValid+=('')
aSettStr+=("logfile_extension");aSettVal+=(".log");aSettValid+=('')

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

create_settings # create fresh if null
read_settings_file "$current_settings_file"

# Settings:
# - git root            0
# - gitpath mod         1
# - gitpath bot         2
# - gitpath log         3
# - server name         4
# - teeworlds bin name  5
# - bot bin name        6
# - cmake flags         7
# - error logs          8
# - error logs api      9
# - editor              10
# - gdb commands        11
# - gdb dump core       12
# - use cstd paste      13
# - post logs dir       14
# - git force pull      15
# - test run            16
# - test run port       17
# - git commit          18
# - git branch          19
# - server type         20
# - tem settings        21
# - tem path            22
# - env build           23
# - env runtime         24
# - log extension       25

export CFG_GIT_ROOT="${aSettVal[0]}"
export CFG_GIT_PATH_MOD="${aSettVal[1]}"
export CFG_GIT_PATH_BOT="${aSettVal[2]}"
export CFG_LOGS_PATH="${aSettVal[3]}"
export CFG_SRV_NAME="${aSettVal[4]}"
export CFG_COMPILED_BIN="${aSettVal[5]}"
export CFG_COMPILED_BIN_BOT="${aSettVal[6]}"
# https://github.com/koalaman/shellcheck/wiki/Sc2086
# https://github.com/koalaman/shellcheck/wiki/SC2206
read -r -a CFG_CMAKE_FLAGS <<< "${aSettVal[7]}"
export CFG_ERROR_LOGS="${aSettVal[8]}" # 0=off 1=no duplicated 2=duplicates
export CFG_ERROR_LOGS_API="${aSettVal[9]}" # shell command that gets executed on error
export CFG_EDITOR="${aSettVal[10]}"
export CFG_GDB_CMDS="${aSettVal[11]}"
export CFG_GDB_DUMP_CORE="${aSettVal[12]}"
# export CFG_DEBUG="${aSettVal[13]}" # debug depends on cmake flags
export CFG_CSTD="${aSettVal[13]}"
export CFG_POST_LOGS_DIR="${aSettVal[14]}"
export CFG_GIT_FORCE_PULL="${aSettVal[15]}"
export CFG_TEST_RUN="${aSettVal[16]}"
export CFG_TEST_RUN_PORT="${aSettVal[17]}"
export CFG_GIT_COMMIT="${aSettVal[18]}"
export CFG_GIT_BRANCH="${aSettVal[19]}"
export CFG_SERVER_TYPE="${aSettVal[20]}"
export CFG_TEM_SETTINGS="${aSettVal[21]}"
export CFG_TEM_PATH="${aSettVal[22]}"
export CFG_ENV_BUILD="${aSettVal[23]}"
export CFG_ENV_RUNTIME="${aSettVal[24]}"
export CFG_LOG_EXT="${aSettVal[25]}"

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

