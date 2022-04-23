#!/bin/bash

if [ ! -f lib/lib.sh ]
then
	echo "Error: lib/lib.sh not found!"
	echo "make sure you are in the root of the server repo"
	exit 1
fi

source lib/lib.sh

get_sid
if [ -f lib/tmp/logfile.txt ]
then
	rm lib/tmp/logfile.txt
fi

arg_multi=''
arg_screen=''

for arg in "$@"
do
	if [ "$arg" == "--help" ] || [ "$arg" == "-h" ]
	then
		echo "usage: $(basename "$0") [OPTIONS..]"
		echo "description:"
		echo "  stops server when started with started.sh"
		echo "  restarts the server when running with loop_gdb.sh or crashsave.sh"
		echo "options:"
		echo "  --help|-h       show this help"
		echo ""
		echo "  --abort-multi   if multiple proccesses found abort stop"
		echo "  --force-multi   if multiple proccesses found kill them all"
		echo ""
		echo "  --abort-screen  if running in screen abort stop"
		echo "  --force-screen  if running in screen kill it anyways"
		exit 0
	elif [ "$arg" == "--abort-multi" ]
	then
		arg_multi=n
	elif [ "$arg" == "--force-multi" ]
	then
		arg_multi=y
	elif [ "$arg" == "--abort-screen" ]
	then
		arg_screen=n
	elif [ "$arg" == "--force-screen" ]
	then
		arg_screen=y
	else
		echo "Error: unkown arg '$arg' try --help"
		exit 1
	fi
done

function kill_by_name() {
	local proc_name=$1
	if ! show_procs_name "$proc_name"
	then
		return
	fi
	if [ "$CFG_SERVER_TYPE" != "tem" ]
	then
		log "other processes containing '$proc_name' were found."
		log "you can stop them all."
		log "but keep it mind it could stop any application on your server not only tw server"
	fi
	log "do you want to stop them all? [y/N]"
	local yn
	yn=''
	if [ "$arg_multi" == "" ]
	then
		read -r -n 1 yn
	else
		echo "$arg_multi"
		yn="$arg_multi"
	fi
	echo ""
	if [[ "$yn" =~ [yY] ]]
	then
		pkill -f "$proc_name"
		log "stopped all processes."
	else
		log "aborting stop script."
	fi
}

proc_str="./$CFG_BIN"

if proc_in_screen "$SERVER_UUID"
then
	log "consider using screen to stop the process"
	log "do you really want to kill the server? [y/N]"
	yn=''
	if [ "$arg_screen" == "" ]
	then
		read -r -n 1 yn
	else
		echo "$arg_screen"
		yn="$arg_screen"
	fi
	echo ""
	if [[ ! "$yn" =~ [yY] ]]
	then
		log "aborting stop script."
		exit
	fi
fi

if pgrep -f "$SERVER_UUID" > /dev/null
then
	pkill -f "$SERVER_UUID"
	log "stopped server with id '$SERVER_UUID'"
else
	wrn "no server with this id found '$SERVER_UUID'"
fi

sleep 0.5 # give server time to shutdown

kill_by_name "$proc_str"
if [ "$CFG_SERVER_TYPE" == "tem" ]
then
	kill_by_name "settings=$CFG_TEM_SETTINGS"
fi

