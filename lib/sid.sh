#!/bin/bash

# each server directory has its own server id
# those are openssl generated base64 encoded
# and they are generated once and then stored into lib/server_id.txt
# they are used to kill the process and make sure not to kill the wrong server

function generate_sid() {
    server_id=$(openssl rand -hex 16)
    echo $server_id > lib/server_id.txt
    log "generated new server id '$server_id'"
}

function get_sid() {
    if [ ! -f lib/server_id.txt ]
    then
        generate_sid
        return
    fi
    server_id=$(cat lib/server_id.txt)
    if [ "$server_id" == "" ]
    then
        wrn "server id empty generating new one..."
        generate_sid
        return
    fi
    len=${#server_id}
    if [ $((len)) -ne 32 ]
    then
        wrn "unexpected sid length found"
        wrn "exptected 32 got $len"
    fi
}
