#!/bin/bash

if [ ! -f lib/lib.sh ]
then
	echo "Error: lib/lib.sh not found!"
	echo "make sure you are in the root of the server repo"
	exit 1
fi

source lib/lib.sh

log -n "echo_pipe.sh [stdin] ... "

if ! diff <(./lib/echo_pipe.sh < ./lib/test/unit/data/echo_pipe.in) ./lib/test/unit/data/echo_pipe.out
then
	echo "FAIL"
	err "echo pipe failed"
	exit 1
else
	echo "OK"
fi

log -n "echo_pipe.sh [multi file] ... "

if ! diff <(./lib/echo_pipe.sh ./lib/test/unit/data/echo_pipe.in ./lib/test/unit/data/echo_pipe.in) <(cat ./lib/test/unit/data/echo_pipe.out ./lib/test/unit/data/echo_pipe.out)
then
	echo "FAIL"
	err "echo pipe failed"
	exit 1
else
	echo "OK"
fi

