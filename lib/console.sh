#!/bin/bash

if [ ! -f lib/lib.sh ]
then
	echo "Error: lib/lib.sh not found!"
	echo "make sure you are in the root of the server repo"
	exit 1
fi

source lib/lib.sh

check_server_dir

message='here could be your ad'

logfile="$(get_latest_logfile)"
last_log_line=''

function render() {
	local newest_line
	newest_line="$(tail -n 1 "$logfile")"
	if [ "$newest_line" == "$last_log_line" ]
	then
		return
	fi
	last_log_line="$newest_line"
	log_height="$(tput lines)"
	log_height="$((log_height - 3))"
	max_width="$(tput cols)"

	tail -n "$log_height" "$logfile"
	printf '%0.s-' $(seq 1 "$max_width")
	echo "$message"
	printf '%0.s-' $(seq 1 "$max_width")
	printf '\n> %s' "$input"
}

function send_fifo() {
	./lib/fifo.sh "$1"
}

render

# avoid 'ENTER' presses scrolling
# this hides all stdin in stdout
stty -echo

while true
do
	printf "\33[%d;%dH%s" "$((log_height + 3))" 3 "$input"
	ifs="$IFS"
	IFS= read -r -t 0.01 -s -d '' -n1 inp
	IFS="$ifs"
	if [ "$inp" == $'\n' ]
	then
		send_fifo "$input"
		input=''
	else
		input+="$inp"
	fi
	render
done

