#!/bin/bash

if [ ! -f lib/lib.sh ]
then
    echo "Error: lib/lib.sh not found!"
    echo "make sure you are in the root of the server repo"
    exit
fi

source lib/lib.sh

source lib/include/update/cmake.sh

function print_default() {
	if [ "$CFG_SERVER_TYPE" == "$1" ]
	then
		tput bold
		printf "(default)"
		tput sgr0
	fi
}

function tem_update() {
	(
		cd "$CFG_TEM_PATH" || exit 1
		git_save_pull
	)
}

arg_type=''

for arg in "$@"
do
	if [ "$arg" == "--help" ] || [ "$arg" == "-h" ]
	then
		echo "usage: ./update.sh [TYPE] [OPTIONS..]"
		echo "type:"
		echo "  teeworlds   compile a teeworlds server $(print_default teeworlds)"
		echo "  tem         update a TeeworldsEconMod repo $(print_default tem)"
		echo "  bot         update side runner bot"
		echo "otpions:"
		echo "  -f|--force      force build dirty git tree"
		exit 0
	elif [ "${arg::1}" != "-" ] && [ "$arg_type" == "" ]
	then
		arg_type="$arg"
		if [[ ! "$arg_type" =~ (teeworlds|tem|bot) ]]
		then
			err "ERROR: invalid update type '$arg_type'"
			err "       valid types: teeworlds, tem, bot"
			exit 1
		fi
		shift
	fi
done

if [ "$arg_type" == "bot" ]
then
	cmake_update_bot "$@"
	update_configs
	git_save_pull
elif [ "$CFG_SERVER_TYPE" == "teeworlds" ] || [ "$arg_type" == "teeworlds" ]
then
	cmake_update_teeworlds "$@"
	git_save_pull
elif [ "$CFG_SERVER_TYPE" == "tem" ] || [ "$arg_type" == "tem" ]
then
	tem_update
	update_configs
	git_save_pull
else
	err "something went wrong :/"
	exit 1
fi

