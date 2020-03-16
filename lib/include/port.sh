#!/bin/bash

port_used=8303
twcfg_line=0
twcfg_last_line="firstline"

function check_cfg() {
    if [ ! -f autoexec.cfg ]
    then
        wrn "autoexec.cfg not found!"
        echo ""
        log "do you want to create one from template? [y/N]"
        yn=""
        read -r -n 1 yn
        echo ""
        if [[ ! "$yn" =~ [yY] ]]
        then
            log "skipping config..."
            return
        fi
        log "editing template cfg..."
        sed "s/SERVER_NAME/$CFG_SRV_NAME/g" lib/autoexec.txt > autoexec.cfg
        vi autoexec.cfg # TODO: make sure vi is installed
    fi
}

function include_exec() {
    local config="$1"
    if [ ! -f "$config" ]
    then
        err "Error: parsing teeworlds config" >&2
        err "  $twcfg_line:$twcfg_last_line" >&2
        err "  file not found: $config" >&2
        exit 1
    fi
    while read -r line
    do
        twcfg_last_line="$line"
        if [[ "$line" =~ ^exec\ \"?(.*\.cfg) ]]
        then
            include_exec "${BASH_REMATCH[1]}"
        else
            echo "$line"
        fi
        twcfg_line="$((twcfg_line + 1))"
    done < "$config"
}

function get_port_used() {
    if [ ! -d lib/ ]
    then
        wrn "could not detect port lib/ directory not found."
        return
    elif [ ! -f autoexec.cfg ]
    then
        # wrn "could not detect port due to missing autoexec.cfg"
        return
    fi
    mkdir -p lib/tmp
    twcfg_line=0
    include_exec "autoexec.cfg" > lib/tmp/compiled.cfg
    port="$(grep '^sv_port ' lib/tmp/compiled.cfg | tail -n1 | cut -d' ' -f2 | xargs)"
    port_used="$port"
    if [ "$port" == "" ]
    then
        # log "no port found in autoexec.cfg fallback to 8303"
        port_used=8303
    elif ! [[ $port =~ ^[0-9]+$ ]]
    then
        err "Invalid non numeric value for sv_port '$port'"
        exit 1
    fi
    log -n "checking port '$port_used' ... "
}

function check_port() {
    check_cfg
    get_port_used
    if netstat --inet -n -a -p 2>/dev/null | grep "$port_used" | grep -qv grep;
    then
        echo ""
        err "error port '$port_used' is already in use"
        exit 1
    fi
    echo "OK"
}

