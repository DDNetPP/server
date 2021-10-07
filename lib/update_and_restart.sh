#!/bin/bash

if [ ! -f lib/lib.sh ]
then
	echo "Error: lib/lib.sh not found!"
	echo "make sure you are in the root of the server repo"
	exit 1
fi

source lib/lib.sh

if ! pgrep -f "$SERVER_UUID" > /dev/null
then
    err "Error: server is not running"
    exit 1
fi

is_loop=0
if is_running_loop
then
	is_loop=1
fi

./update.sh

for i in {10..0}
do
	if [ ! "$i" -eq 0 ]
	then
		./lib/fifo.sh "broadcast ^009Server restart in $i"
		./lib/fifo.sh "say Server restart in $i"
		sleep 1
	else
		./lib/fifo.sh "broadcast ^009Server restart completed"
		./lib/fifo.sh "say Server restart completed"
		sleep 1
	fi
done

./lib/fifo.sh "shutdown Server is restarting, reconnect please..."
sleep 0.5

./update.sh --refresh

if [ "$is_loop" == "0" ]
then
	./start.sh --no
fi

