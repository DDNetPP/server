#!/bin/bash

# TODO: make this a proper side runner that can be turned on and off in cnf

if [ ! -f lib/lib.sh ]
then
	echo "Error: lib/lib.sh not found!"
	echo "make sure you are in the root of the server repo"
	exit 1
fi

source lib/lib.sh

LOGFILE="${1:-logs/traffic.txt}"
CHECK_DDOS_INTERVAL=1
DDOS_TRESHOLD=6

current_interval=0

# server_ip="$(get_tw_config bindaddr 127.0.0.1)"
# server_port="$(get_tw_config sv_port 8303)"
# if [ "$server_ip" == "127.0.0.1" ]
# then
# 	if [ ! "$(command -v curl)" ]
# 	then
# 		err "Error: command $(tput bold)curl$(tput sgr0) not found"
# 		err "	    could not determine ip address"
# 	else
# 		server_ip="$(curl https://ipinfo.io/ip)"
# 	fi
# fi
# if [ "$server_ip" == "" ]
# then
# 	err "could not determine ip address"
# fi

if [ ! "$(command -v rg)" ]
then
	err "Error: ripgrep not found"
	exit 1
fi

mkdir -p logs/ddos

function log_ddos() {
	local logfile
	local lines
	local player_ips
	local players
	local ddos_log
	logfile="$1"
	if [ ! -f "$logfile" ]
	then
		return
	fi
	# if [ "$server_ip" == "" ]
	# then
	# 	return
	# fi
	# players="$(
	# 	curl https://master1.ddnet.tw/ddnet/15/servers.json |
	# 	jq ".[][] | select(.addresses[0] == \"tw-0.6+udp://$server_ip:$server_port\").info.clients | length"
	# )" || { wrn "could not fetch server info"; return; }
	lines="$(sed '1,/^DESTINATION$/d' "$logfile" | wc -l)"
	player_ips="$(get_player_ips)"
	players="$(echo "$player_ips" | wc -l)"
	if [ "$players" == "" ]
	then
		wrn "could not get players"
		return
	fi
	if [ "$((lines-DDOS_TRESHOLD))" -gt "$players" ]
	then
		log "ddos detected players=$players ips=$lines"
		ddos_log="logs/ddos/traffic_$(date '+%F_%H-%M').txt"
		{
			echo "REAL PLAYERS=$players"
			echo "$player_ips" | awk '{ print "\t" $1 }'
			cat "$logfile"
		} > "$ddos_log"
	fi
	log "check ddos players=$players ips=$lines (treshold=$DDOS_TRESHOLD)"
}

while true
do
	./lib/network.sh --plain -t 3 src dst > "$LOGFILE".tmp
	cp "$LOGFILE".tmp "$LOGFILE"
	current_interval="$((current_interval+1))"
	if [ "$current_interval" -ge "$CHECK_DDOS_INTERVAL" ]
	then
		log_ddos "$LOGFILE"
		current_interval=0
	fi
	sleep 1
done

