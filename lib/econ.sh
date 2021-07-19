#!/bin/bash

if [ ! -f lib/lib.sh ]
then
    echo "Error: lib/lib.sh not found!"
    echo "make sure you are in the root of the server repo"
    exit 1
fi

source lib/lib.sh

if [ "$1" == "--help" ] || [ "$1" == "-h" ] || [ "$#" == "0" ]
then
    echo "usage: ./lib/econ.sh <econ command>"
    echo ""
    echo "examples:"
    echo '  ./lib/econ.sh "shutdown"'
    echo '  ./lib/econ.sh "sv_shutdown_when_empty 1"'
    echo '  ./lib/econ.sh "broadcast HELLO HOOMANS;say HELLO HOOMANS"'
    echo '  ./lib/econ.sh "exec script.cfg"'
    exit 0
fi

check_server_dir

if [ ! -x "$(command -v expect)" ]
then
    err "Error: install expect"
    exit 1
fi

ec_port="$(get_tw_config ec_port 0)"
ec_password="$(get_tw_config ec_password "")"

if [ "$ec_port" == "0" ]
then
    err "Error: ec_port not set"
    exit 1
fi
if [ "$ec_password" == "0" ]
then
    err "Error: ec_password not set"
    exit 1
fi

if ! pgrep -f "$SERVER_UUID"
then
    err "Error: server is not running"
    err "       ./start.sh"
    exit 1
fi

./lib/econ-exec.exp localhost "$ec_port" "$ec_password" "$*"

