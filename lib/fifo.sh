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
	echo "usage: ./lib/fifo.sh <rcon command>"
	echo ""
	echo "examples:"
	echo '  ./lib/fifo.sh "shutdown"'
	echo '  ./lib/fifo.sh "sv_shutdown_when_empty 1"'
	echo '  ./lib/fifo.sh "broadcast HELLO HOOMANS;say HELLO HOOMANS"'
	echo '  ./lib/fifo.sh "exec script.cfg"'
	exit 0
fi

check_server_dir

fifo_file="$(get_tw_config sv_input_fifo "")"
if [ "$fifo_file" == "" ]
then
	fifo_file="$(get_tw_config cl_input_fifo "")"
fi

if [ "$fifo_file" == "" ]
then
	err "Error: sv_input_fifo not set"
	exit 1
fi

if ! pgrep -f "$SERVER_UUID" > /dev/null
then
	err "Error: server is not running"
	err "       ./start.sh"
	exit 1
fi

if [ ! -e "$fifo_file" ]
then
	err "Error: file '$fifo_file' does not exist"
	pwd
	exit 1
fi

echo "$*" > "$fifo_file"

