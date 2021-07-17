#!/bin/bash

if [ ! -f lib/lib.sh ]
then
	echo "Error: lib/lib.sh not found!"
	echo "make sure you are in the root of the server repo"
	exit 1
fi

source lib/lib.sh

logpath=""
follow=""

for arg in "$@"
do
	if [ "$arg" == "--help" ] || [ "$1" == "-h" ]
	then
		echo "usage: ./show_log.sh [logname] [-f] [logname]"
		echo "options:"
		echo "  -h          show this help"
		echo "  -f          follows log using tail -f"
		echo "	--tem	    ignore logname when used as TeeworldsEconMod input"
		echo "  logname     directory in ./logs/logname for local log types"
		exit 0
	elif [ "$arg" == "--tem" ]
	then
		follow=-f
		uuid="$(generate_uuid)"
		current_file="$(get_latest_logfile)"
		show_latest_log "$follow" "$logpath" --id="$uuid" &
		while true
		do
			if [ "$current_file" != "$(get_latest_logfile)" ]
			then
				pkill -f "--id=$uuid"
				pkill -f "tail.*$current_file"
				current_file="$(get_latest_logfile)"
				show_latest_log "$follow" "$logpath" --id="$uuid" &
			fi
			sleep 1
		done
		break
	elif [ "$arg" == "-f" ]
	then
		follow=-f
	elif [ "$logpath" == "" ]
	then
		logpath="$arg"
	fi
done

show_latest_log "$follow" "$logpath"

