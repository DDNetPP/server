#!/bin/bash

# init variables
settings_file="server.cnf"
aSettStr=();aSettVal=()
aSettStr+=("gitpath_src");aSettVal+=("/home/chiller/git")
aSettStr+=("gitpath_mod");aSettVal+=("/home/chiller/git/mod")
aSettStr+=("gitpath_log");aSettVal+=("/home/chiller/.teeworlds/dumps")
aSettStr+=("server_name");aSettVal+=("teeworlds")

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
        nano $settings_file
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
                printf "[setting] (%s)%-16s=  %s\n" "$i" "$sett" "$val"
                if [[ "${aSettStr[$i]}" =~ path ]]
                then
                    val="${val%%+(/)}" # strip trailing slash
                fi
                aSettVal[$i]="$val"
                return
            fi
        done
        log "SettingsError: unkown setting $sett"
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

export gitpath_src="${aSettVal[0]}"
export gitpath_mod="${aSettVal[1]}"
export gitpath_log="${aSettVal[2]}"
export srv_name="${aSettVal[3]}"
export srv=bin/$srv_name

