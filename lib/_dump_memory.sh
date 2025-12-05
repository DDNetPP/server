#!/bin/bash

server_pid="$1"

if [ "$server_pid" = "" ]
then
	err "missing argument pid"
	exit 1
fi
if ! ps -p "$server_pid" > /dev/null
then
	err "Server process not found. Is the server running?"
	exit 1
fi

dump_dir=logs/dump_memory
rm -rf "$dump_dir"
mkdir -p "$dump_dir"

# https://serverfault.com/a/408929
grep rw-p /proc/${server_pid}/maps \
	| sed -n 's/^\([0-9a-f]*\)-\([0-9a-f]*\) .*$/\1 \2/p' \
	| while read start stop; do \
	gdb --batch --pid "${server_pid}" -ex \
	"dump memory ${dump_dir}/${server_pid}-$start-$stop.dump 0x$start 0x$stop"; \
done

echo "[*] dumped server memory to $dump_dir .. OK"
