#!/bin/bash

if [ ! -f lib/lib.sh ]
then
	echo "Error: lib/lib.sh not found!"
	echo "make sure you are in the root of the server repo"
	exit 1
fi

source lib/lib.sh

log -n "audit_code.sh [_get_grep_context ':'] ... "

if [ "$(_get_grep_context 'src/game/client/gameclient.cpp:580: // render all systems')" != ":" ]
then
	echo "FAIL"
	err "_get_grep_context failed"
	exit 1
else
	echo "OK"
fi


log -n "audit_code.sh [_get_grep_context '-'] ... "

if [ "$(_get_grep_context 'src/game/client/gameclient.cpp-580- // render all systems')" != "-" ]
then
	echo "FAIL"
	err "_get_grep_context failed"
	exit 1
else
	echo "OK"
fi

log -n "audit_code.sh [_chop_grep_line ':'] ... "

if ! diff <(_chop_grep_line 'src/game/client/gameclient.cpp:580: // render all systems') \
	<(echo " // render all systems")
then
	echo "FAIL"
	err "_chop_grep_line failed"
	exit 1
else
	echo "OK"
fi

log -n "audit_code.sh [_chop_grep_line '-'] ... "

if ! diff <(_chop_grep_line 'src/game/client/gameclient.cpp-580- // render all systems') \
	<(echo " // render all systems")
then
	echo "FAIL"
	err "_chop_grep_line failed"
	exit 1
else
	echo "OK"
fi
