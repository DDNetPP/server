#!/bin/bash

if [ ! -f lib/lib.sh ]
then
    echo "Error: lib/lib.sh not found!"
    echo "make sure you are in the root of the server repo"
    exit 1
fi

source lib/lib.sh

check_deps "$1"
check_warnings
check_running


arg_is_interactive=0
arg_logs=1
arg_tmp_map_url=""

for arg in "$@"
do
	if [ "$arg" == "--help" ] || [ "$arg" == "-h" ]
	then
		echo "usage: ./start.sh [map url] [OPTION]"
		echo "options:"
		echo "  -i|--interactive        no logfiles and daemon"
		echo "  -n|--no            	do not prompt for showing logs"
		echo "map url:"
		echo ""
		echo "  when no arguemnt provided a production server is started"
		echo "  it is writing a logfile and running in the background"
		echo ""
		echo "  when the map argument is provided a test server is started"
		echo "  the map will be downloaded into maps/tmp/mapname.map"
		echo "  and the server will be started with that map and running in the foreground"
		echo "  no logfile will be written"
		exit 0
	elif [ "${arg::1}" == "-" ]
	then
		if [ "$arg" == "-i" ] || [ "$arg" == "--interactive" ]
		then
			arg_is_interactive=1
		elif [ "$arg" == "-n" ] || [ "$arg" == "--no" ]
		then
			arg_logs=0
		else
			err "invalid argument '$arg' see '--help'"
			exit 1
		fi
	elif [ "$arg_tmp_map_url" == "" ]
	then
		arg_tmp_map_url="$arg"
	else
		err "unexpected argument '$arg' see '--help'"
		exit 1
	fi
done

archive_gmon
restart_side_runner

if [ "$arg_tmp_map_url" != "" ]
then
    if ! [[ "$arg_tmp_map_url" =~ (http|www).*\.map ]]
    then
        err "invalid url '$arg_tmp_map_url'"
        exit 1
    fi
    if [ ! -d maps/ ]
    then
        err "maps directory not found."
        exit 1
    fi
    mkdir -p maps/tmp
    cd maps/tmp || exit 1
    mapname="${arg_tmp_map_url##*/}"
    if ! [[ "$mapname" =~ .map$ ]]
    then
        err "Failed to parse mapname '$mapname'"
        exit 1
    fi
    if [ -f "$mapname" ]
    then
        rm "$mapname"
    fi
    mapname="$(basename "$mapname" .map)"
    log "downloading map '$mapname' ..."
    wget "$arg_tmp_map_url"
    cd ../../ || exit 1
    read -rp 'password: ' pass
    log "starting server with password '$pass' ..."
    ./"$CFG_BIN" "sv_map tmp/$mapname;password $pass"
    exit 0
fi

log_ext="${CFG_LOG_EXT:-.log}"
if [ "$CFG_SERVER_TYPE" == "tem" ]
then
	logfile="${SCRIPT_ROOT}/logs/tem/vanilla_tem_$(date +%F_%H-%M-%S)${log_ext}"
	mkdir -p logs/tem
	cd "$CFG_TEM_PATH" || exit 1
	if [ "$arg_is_interactive" == "1" ]
	then
		./start_tem.sh "$CFG_TEM_SETTINGS" "#sid:$SERVER_UUID"
	else
		nohup ./start_tem.sh "$CFG_TEM_SETTINGS" "#sid:$SERVER_UUID" > "$logfile" 2>&1 &
	fi
else # teeworlds
	logfile="$LOGS_PATH_FULL/${CFG_SRV_NAME}_$(date +%F_%H-%M-%S)${log_ext}"
	cache_logpath "$logfile"

	run_cmd="$CFG_ENV_RUNTIME nohup ./$CFG_BIN \"#sid:$SERVER_UUID\" > $logfile 2>&1 &"
	if [ "$arg_is_interactive" == "1" ]
	then
		run_cmd="$CFG_ENV_RUNTIME ./$CFG_BIN \"#sid:$SERVER_UUID\""
	fi
	log "running:"
	tput bold
	echo "$run_cmd"
	tput sgr0
	eval "$run_cmd"

	if [ "$arg_logs" == "1" ]
	then
		show_log_file "$logfile"
	fi
fi

