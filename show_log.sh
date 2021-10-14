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
arg_no_args=0

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
	elif [ "$arg" == "--" ]
	then
		arg_no_args=1
	elif [ "${arg::1}" == "-" ] && [ "$arg_no_args" == "0" ]
	then
		if [ "$arg" == "--filepath" ]
		then
			arg_print=1
		elif [ "$arg" == "--tem" ]
		then
			# use config tem_side_runner=1
			# to pickup restarts
			show_latest_log -f "$arg_logpath"
			exit 0
		elif [ "$arg" == "-f" ]
		then
			arg_follow=-f
		else
			err "Error: unkown flag '$arg' see '--help'"
			exit 1
		fi
	elif [ "$logpath" == "" ]
	then
		arg_logpath="$arg"
	fi
done

if [ "$arg_print" == "1" ]
then
	if [ "$arg_logpath" == "" ]
	then
		get_latest_logfile
	else
		get_latest_logfile "./logs/$arg_logpath"
	fi
	exit 0
fi

show_latest_log "$arg_follow" "$arg_logpath"

