#!/bin/bash

# each server directory has its own server UUID
# and they are generated once and then stored into lib/var/.server_id
# they are used to kill the process and make sure not to kill the wrong server

SID_FILE=lib/var/.server_id
OLD_SID_FILE=lib/.server_id # backwards compability

function generate_uuid() {
	od -xN16 /dev/urandom | awk -v OFS=- '{print $2$3,$4,$5,$6,$7$8$9; exit}'
}

function generate_sid() {
	server_id="$(generate_uuid)"
	echo "$server_id" > "$SID_FILE"
	log "generated new server UUID '$server_id'"
}

function get_sid() {
    if [ ! -d lib/var/ ]
    then
        check_server_dir
        wrn "creating directory 'lib/var' ..."
        mkdir -p lib/var || { err "failed to create directory 'lib/var'"; exit 1; }
    fi
    if [ ! -f "$SID_FILE" ]
    then
        if [ -f "$OLD_SID_FILE" ]
        then
            log "detected old sid file move to new position ..."
            mv "$OLD_SID_FILE" "$SID_FILE"
        else
            generate_sid
            return
        fi
    fi
    server_id="$(cat "$SID_FILE")"
    if [ "$server_id" == "" ]
    then
        wrn "server id empty generating new one..."
        generate_sid
        return
    fi
    len="${#server_id}"
    if [ $((len)) -ne 36 ]
    then
        wrn "unexpected UUID length found"
        wrn "exptected 36 got $len"
    fi
}

get_sid

