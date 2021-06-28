#!/bin/bash

# TODO: make this a proper side runner that can be turned on and off in cnf

LOGFILE="${1:-logs/traffic.txt}"

while true
do
	./lib/network.sh --plain -t 3 src dst > "$LOGFILE".tmp
	cp "$LOGFILE".tmp "$LOGFILE"
	sleep 1
done

