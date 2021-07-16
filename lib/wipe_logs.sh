#!/bin/bash

if [ ! -f lib/lib.sh ]
then
	echo "Error: lib/lib.sh not found!"
	echo "make sure you are in the root of the server repo"
	exit 1
fi

source lib/lib.sh

function show_help() {
	echo "usage: ./lib/$(basename "$0") [OPTION]"
	echo "description:"
	echo "  display short logs to the user and prompt for deletion"
	echo "options:"
	echo "  --help|-h	show this help"
	echo "  --all|-a	execute it for all servers in current dir"
}

if [ "$1" == "--help" ] || [ "$1" == "-h" ] || [ "$1" == "help" ]
then
	show_help
	exit 0
elif [ "$1" == "--all" ] || [ "$1" == "-a" ]
then
	./lib/exec_all_servers.sh "./lib/$(basename "$0")"
	exit 0
elif [ "$#" -gt "0" ]
then
	show_help
	exit 1
fi

function wipe_log() {
	local logfile="$1"
	if [ -f "$logfile" ]
	then
		log " <===> $(tput bold)$(basename "$(pwd)")$(tput sgr0) <===>"
		cat "$logfile"
		log "delete $logfile? [y/N]"
		yn=""
		read -rn 1 yn
		if [[ "$yn" =~ [yY] ]]
		then
			rm "$logfile"
			log "deleting $logfile ..."
		fi
	fi
}

function wipe_tw_logs() {
	local logfile
	local size
	local max_height
	max_height="$(tput lines)"
	max_height="$((max_height-10))"
	for logfile in "$LOGS_PATH_FULL/"*
	do
		if [ "$size" -gt "150" ]
		then
			continue
		fi
		log " <===> $(tput bold)$(basename "$(pwd)")$(tput sgr0) <===>"
		size="$(wc -l "$logfile" | cut -d' ' -f1)"
		if [ "$size" -gt "$max_height" ]
		then
			head -n "$((max_height/2))" "$logfile"
			echo "[..]"
			tail -n "$((max_height/2))" "$logfile"
		else
			cat "$logfile"
		fi
		log "delete $logfile? [y/N]"
		yn=""
		read -rn 1 yn
		if [[ "$yn" =~ [yY] ]]
		then
			rm "$logfile"
			log "deleting $logfile ..."
		fi
	done
}

wipe_log bt.txt
wipe_tw_logs

