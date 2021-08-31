#!/bin/bash

if [ ! -f lib/lib.sh ]
then
	echo "Error: lib/lib.sh not found!"
	echo "make sure you are in the root of the server repo"
	exit 1
fi

source lib/lib.sh

log -n "traffic_logger.sh [show_known_ips] ... "

mkdir -p ./lib/tmp/test
cp ./lib/test/unit/data/traffic_raw.txt ./lib/tmp/test/traffic_raw.txt
show_known_ips ./lib/tmp/test/traffic_raw.txt ./lib/known_ips.txt
if ! diff \
	./lib/tmp/test/traffic_raw.txt \
	./lib/test/unit/data/traffic_known_ips.txt
then
	echo "FAIL"
	err "show_known_ips failed"
	exit 1
else
	echo "OK"
fi


