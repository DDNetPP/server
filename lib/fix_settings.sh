#!/bin/bash

if [ ! -f lib/lib.sh ]
then
	echo "Error: lib/lib.sh not found!"
	echo "make sure you are in the root of the server repo"
	exit 1
fi

export IS_SETT_FIX=1

source lib/lib.sh

rename_old_settings server.cnf

