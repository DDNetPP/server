#!/bin/bash
shopt -s extglob # used for trailing slashes globbing

# init variables
settings_file="server.cnf"
line_num=0
aSettStr=();aSettVal=();aSettValid=()
aSettStr+=("git_root");aSettVal+=("/home/$USER/git");aSettValid+=('')
aSettStr+=("gitpath_mod");aSettVal+=("/home/$USER/git/mod");aSettValid+=('')
aSettStr+=("gitpath_log");aSettVal+=("/home/$USER/.teeworlds/dumps/TeeworldsLogs");aSettValid+=('')
aSettStr+=("server_name");aSettVal+=("teeworlds");aSettValid+=('')
aSettStr+=("compiled_binary_name");aSettVal+=("teeworlds_srv");aSettValid+=('')
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

function create_settings() {
    if [ -f $settings_file ];
    then
        return
    fi
    local i
    log "FileError: '$settings_file' not found"
    read -p "Do you want to create one? [y/N]" -n 1 -r
    echo 
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        echo "# DDNet++ server config by ChillerDragon" > "$settings_file"
        echo "# https://github.com/DDNetPP/server" >> "$settings_file"
        for i in "${!aSettStr[@]}"
        do
            echo "${aSettStr[$i]}=${aSettVal[$i]}" >> "$settings_file"
        done
        edit_file "$settings_file"
    fi
    exit 1
}

function parse_settings_line() {
        local sett=$1
        local val=$2
        if [ "$sett" == "binary_name" ]
        then
            wrn "WARNING: 'binary_name' is deprecated by 'compiled_binary_name'"
            wrn "         please fix at $settings_file:$line_num"
            sett=compiled_binary_name
        elif [ "$sett" == "gitpath_src" ]
        then
            wrn "WARNING: 'gitpath_src' is deprecated by 'git_root'"
            wrn "         please fix at $settings_file:$line_num"
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
                    err "SettingsError: invalid value '$val' for setting '$sett'"
                    err "               values have to match $valid_pattern"
                    exit 1
                fi
                aSettVal[$i]="$val"
                return
            fi
        done
        err "SettingsError: unkown setting $sett"
        exit 1
}

function read_settings_file() {
    local i
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
        line_set=""
        line_val=""
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
    done < "$settings_file"
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
read_settings_file

# Settings:
# - git root            0
# - gitpath mod         1
# - gitpath log         2
# - server name         3
# - compiled bin name   4
# - cmake flags         5
# - error logs          6
# - error logs api      7
# - editor              8
# - gdb commands        9
# - gdb dump core       10
# - use cstd paste      11
# - post logs dir       12
# - git force pull      13
# - test run            14
# - test run port       15
# - git commit          16
# - git branch          17
# - server type         18
# - tem settings        19
# - tem path            20

export CFG_GIT_ROOT="${aSettVal[0]}"
export CFG_GIT_PATH_MOD="${aSettVal[1]}"
export CFG_LOGS_PATH="${aSettVal[2]}"
export CFG_SRV_NAME="${aSettVal[3]}"
export CFG_COMPILED_BIN="${aSettVal[4]}"
# https://github.com/koalaman/shellcheck/wiki/Sc2086
# https://github.com/koalaman/shellcheck/wiki/SC2206
read -r -a CFG_CMAKE_FLAGS <<< "${aSettVal[5]}"
export CFG_ERROR_LOGS="${aSettVal[6]}" # 0=off 1=no duplicated 2=duplicates
export CFG_ERROR_LOGS_API="${aSettVal[7]}" # shell command that gets executed on error
export CFG_EDITOR="${aSettVal[8]}"
export CFG_GDB_CMDS="${aSettVal[9]}"
export CFG_GDB_DUMP_CORE="${aSettVal[10]}"
# export CFG_DEBUG="${aSettVal[11]}" # debug depends on cmake flags
export CFG_CSTD="${aSettVal[11]}"
export CFG_POST_LOGS_DIR="${aSettVal[12]}"
export CFG_GIT_FORCE_PULL="${aSettVal[13]}"
export CFG_TEST_RUN="${aSettVal[14]}"
export CFG_TEST_RUN_PORT="${aSettVal[15]}"
export CFG_GIT_COMMIT="${aSettVal[16]}"
export CFG_GIT_BRANCH="${aSettVal[17]}"
export CFG_SERVER_TYPE="${aSettVal[18]}"
export CFG_TEM_SETTINGS="${aSettVal[19]}"
export CFG_TEM_PATH="${aSettVal[20]}"

if [ "$CFG_SERVER_TYPE" == "tem" ]
then
    tem_settings_path="$CFG_TEM_PATH/$CFG_TEM_SETTINGS"
    if [ ! -f "$tem_settings_path" ]
    then
        err "ERROR: tem settings file not found"
        err "       $tem_settings_path"
        exit 1
    fi
    CFG_LOGS_PATH="$(grep sh_logs_path "$tem_settings_path" | cut -d'=' -f2-)"
    if [ "${CFG_LOGS_PATH::1}" != "/" ]
    then
        CFG_LOGS_PATH="$HOME/.teeworlds/dumps/$CFG_LOGS_PATH"
    fi
fi
CFG_LOGS_PATH="${CFG_LOGS_PATH%%+(/)}" # strip trailing slash
LOGS_PATH_TW="$CFG_LOGS_PATH"
is_dumps_logpath=0

if [ "$CFG_LOGS_PATH" == "" ]
then
    err "[setting] gitpath_log can not be empty"
    exit 1
fi

if [[ $CFG_LOGS_PATH =~ \.teeworlds/dumps/ ]]
then
    log "detected 0.7 logpath"
    # only use the relative part starting from dumps dir
    LOGS_PATH_TW="${CFG_LOGS_PATH##*.teeworlds/dumps/}"
    is_dumps_logpath=1
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
LOGS_PATH_FULL="$CFG_LOGS_PATH/$CFG_SRV_NAME/logs/"
LOGS_PATH_FULL_TW="$LOGS_PATH_TW/$CFG_SRV_NAME/logs/"
if [ "$CFG_SERVER_TYPE" == "tem" ]
then
    LOGS_PATH_FULL="$CFG_LOGS_PATH"
    LOGS_PATH_FULL_TW="$LOGS_PATH_TW"
fi

export CFG_CMAKE_FLAGS # usage: "${CFG_CMAKE_FLAGS[@]}"
export is_dumps_logpath
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

