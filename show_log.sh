#!/bin/bash

if [ ! -f lib/lib.sh ]
then
	echo "Error: lib/lib.sh not found!"
	echo "make sure you are in the root of the server repo"
	exit 1
fi

source lib/lib.sh

arg_logpath=""
arg_follow=""
arg_print=0

for arg in "$@"
do
	if [ "$arg" == "--help" ] || [ "$1" == "-h" ]
	then
		echo "usage: ./show_log.sh [logname] [OPTION] [logname]"
		echo "options:"
		echo "  -h          show this help"
		echo "  -f          follows log using tail -f"
		echo "  --filepath  print the file path to the logfile and nothing else"
		echo "  --tem       ignore logname when used as TeeworldsEconMod input"
		echo "  logname     directory in ./logs/logname for local log types"
		exit 0
	elif [ "$arg" == "--filepath" ]
	then
		arg_print=1
	elif [ "$arg" == "--tem" ]
	then
		arg_follow=-f
		uuid="$(generate_uuid)"
		current_file="$(get_latest_logfile)"
		show_latest_log "$arg_follow" "$arg_logpath" --id="$uuid" &
		while true
		do
			if [ "$current_file" != "$(get_latest_logfile)" ]
			then
				pkill -f "id=$uuid"
				pkill -f "tail.*$current_file"
				current_file="$(get_latest_logfile)"
				show_latest_log "$arg_follow" "$arg_logpath" --id="$uuid" &
			fi
			sleep 1
		done
		break
	elif [ "$arg" == "-f" ]
	then
		arg_follow=-f
	elif [ "$logpath" == "" ]
	then
		arg_logpath="$arg"
	fi
done

if [ "$arg_print" == "1" ]
then
	get_latest_logfile "./logs/$arg_logpath"
	exit 0
fi

show_latest_log "$arg_follow" "$arg_logpath"

