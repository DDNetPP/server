#!/bin/bash

function show_known_ips() {
	local logfile="$1"
	local ip_db="$2"
	local file_buffer
	local line
	local ip
	if [ ! -f "$ip_db" ]
	then
		return
	fi
	file_buffer="$(cat "$logfile")"
	while read -r line
	do
		if [ "$(echo "$line" | xargs)" == "" ]
		then
			continue
		fi
		ip="$(echo "$line" | cut -d' ' -f1)"
		file_buffer="${file_buffer//$ip/$line}"
	done < "$ip_db"
	printf "%s\n\n" "$file_buffer" > "$logfile".tmp
	mv "$logfile".tmp "$logfile"
}

