#!/bin/bash
shopt -s extglob # used for trailing slashes globbing

# init variables
settings_file="server.cnf"
aSettStr=();aSettVal=()
aSettStr+=("gitpath_src");aSettVal+=("/home/chiller/git")
aSettStr+=("gitpath_mod");aSettVal+=("/home/chiller/git/mod")
aSettStr+=("gitpath_log");aSettVal+=("/home/chiller/.teeworlds/dumps/TeeworldsLogs")
aSettStr+=("server_name");aSettVal+=("teeworlds")
aSettStr+=("binary_name");aSettVal+=("teeworlds_srv")
aSettStr+=("cmake_flags");aSettVal+=("-DCMAKE_BUILD_TYPE=Debug")
aSettStr+=("error_logs");aSettVal+=("1")
# aSettStr+=("error_logs_api");aSettVal+=("curl -d \"{\\\"err\\\":\\\"\$err\\\"}\" -H 'Content-Type: application/json' http://localhost:80/api")
aSettStr+=("error_logs_api");aSettVal+=("test")
aSettStr+=("editor");aSettVal+=("")

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

create_settings # create fresh if null
read_settings_file

# Settings:
# - gitpath src     0
# - gitpath mod     1
# - gitpath log     2
# - server name     3
# - binary name     4
# - cmake flags     5
# - error logs      6
# - error logs api  7
# - editor          8

export gitpath_src="${aSettVal[0]}"
export gitpath_mod="${aSettVal[1]}"
export gitpath_log="${aSettVal[2]}"
export CFG_SRV_NAME="${aSettVal[3]}"
export binary_name="${aSettVal[4]}"
# https://github.com/koalaman/shellcheck/wiki/Sc2086
# https://github.com/koalaman/shellcheck/wiki/SC2206
read -r -a CFG_CMAKE_FLAGS <<< "${aSettVal[5]}"
export CFG_CMAKE_FLAGS # usage: "${CFG_CMAKE_FLAGS[@]}"
export CFG_ERROR_LOGS="${aSettVal[6]}" # 0=off 1=no duplicated 2=duplicates
export CFG_ERROR_LOGS_API="${aSettVal[7]}" # shell command that gets executed on error
export CFG_EDITOR="${aSettVal[8]}"
export CFG_BIN=bin/$CFG_SRV_NAME

gitpath_log="${gitpath_log%%+(/)}" # strip trailing slash
logroot="$gitpath_log"
is_dumps_logpath=0

if [ "$gitpath_log" == "" ]
then
    err "[setting] gitpath_log can not be empty"
    exit 1
fi

if [[ $gitpath_log =~ \.teeworlds/dumps ]]
then
    log "detected 0.7 logpath"
    # only use the relative part starting from dumps dir
    logroot="${gitpath_log##*.teeworlds/dumps/}"
    is_dumps_logpath=1
    if [ "$logroot" == "" ]
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

export is_dumps_logpath
export logroot

