#!/bin/bash

function show_known_ips() {
	local logfile="$1"
	local ip_db="$2"
	local line
	local ip
	if [ ! -f "$ip_db" ]
	then
		return
	fi
	while read -r line
	do
		if [ "$(echo "$line" | xargs)" == "" ]
		then
			continue
		fi
		ip="$(echo "$line" | cut -d' ' -f1)"
		# TODO: get this IO out of the loop
		# this is possible thousands of IO calls per function call
		sed "s/$ip/$line/" "$logfile" > "$logfile".tmp
		mv "$logfile".tmp "$logfile"
	done < "$ip_db"
}

