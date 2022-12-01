#!/bin/bash

if [ ! -f lib/lib.sh ]
then
	echo "Error: lib/lib.sh not found!"
	echo "make sure you are in the root of the server repo"
	exit 1
fi

source lib/lib.sh

check_server_dir

logfile="$(get_latest_logfile)"

function render() {
	log_height="$(tput lines)"
	log_height="$((log_height - 3))"
	max_width="$(tput cols)"

	tail -n "$log_height" "$logfile"
	printf '%0.s-' $(seq 1 "$max_width")
	echo "you have to manually press enter to refresh the log because devs are drunk"
	printf '%0.s-' $(seq 1 "$max_width")
	printf '\n> %s' "$input"
}

function send_fifo() {
	./lib/fifo.sh "$1"
}

render

while true
do
	tput cup "$((log_height + 2))" 1
	ifs="$IFS"
	IFS= read -n 1 -r -p "" inp
	IFS="$ifs"
	if [ "$inp" == '' ]
	then
		send_fifo "$input"
		input=''
	elif [ "$inp" == $'^?' ]
	then
		input=''
	fi
	input+="$inp"
	render
done

