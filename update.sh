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
arg_refresh=0

for arg in "$@"
do
	if [ "$arg" == "--help" ] || [ "$arg" == "-h" ]
	then
		echo "usage: ./update.sh [TYPE] [OPTIONS..]"
		echo "type:"
		echo "  teeworlds   compile a teeworlds server $(print_default teeworlds)"
		echo "  tem         update a TeeworldsEconMod repo $(print_default tem)"
		echo "  bot         update side runner bot"
		echo "options:"
		echo "  -f|--force      force build dirty git tree"
		echo "  --refresh       only update binary no rebuild (for now teeworlds only)"
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
	elif [ "$arg" == "--refresh" ]
	then
		arg_refresh=1
	else
		err "Error: unknown argument '$arg' try --help"
		exit 1
	fi
done

function map_themes_pre() {
	if [ ! -d "$CFG_GIT_ROOT"/maps-scripts ]
	then
		return
	fi
	OldMapHashes=()
	local theme
	for theme in "$CFG_GIT_ROOT"/maps-scripts/*/
	do
		local theme="$(basename "$theme")"
		if [ -f ./maps/"$theme".map ]
		then
			OldMapHashes["$theme"]="$(sha1sum ./maps/"$theme".map | cut -d' ' -f1)"
		fi
	done
}
function map_themes_post() {
	if [ ! -d "$CFG_GIT_ROOT"/maps-scripts ]
	then
		return
	fi
	local theme
	local t
	for theme in "$CFG_GIT_ROOT"/maps-scripts/*/
	do
		theme="$(basename "$theme")"
		log "theme $theme"
		if [ -f ./maps/"$theme".map ]
		then
			if [ "${OldMapHashes["$theme"]}" != "$(sha1sum ./maps/"$theme".map | cut -d' ' -f1)" ]
			then
				log "map '$theme' updated generating new themes ..."
				log "  old: ${OldMapHashes["$theme"]}"
				log "  new: $(sha1sum ./maps/"$theme".map | cut -d' ' -f1)"
				for t in "$CFG_GIT_ROOT"/maps-scripts/"$theme"/*.py
				do
					log "generating '$(basename "$t" .py)' theme for '$theme' ..."
					mkdir -p ./designs/"$theme"
					"$t" ./maps/"$theme".map ./designs/"$theme"/"$(basename "$t" .py)".map
				done
			else
				log "skipping non updated map"
				log "  old: ${OldMapHashes["$theme"]}"
				log "  new: $(sha1sum ./maps/"$theme".map | cut -d' ' -f1)"
			fi
		fi
	done
}

if [ "$arg_type" == "bot" ]
then
	if [ "$arg_refresh" == "1" ]
	then
		err "Error: --refresh is not supported for bot yet"
		exit 1
	fi
	cmake_update_bot "$@"
	update_configs
	git_save_pull
elif [ "$CFG_SERVER_TYPE" == "teeworlds" ] || [ "$arg_type" == "teeworlds" ]
then
	if [ "$arg_refresh" == "1" ]
	then
		cmake_refresh_teeworlds_binary
		exit 0
	fi
	map_themes_pre
	cmake_update_teeworlds "$@"
	map_themes_post
	git_save_pull
elif [ "$CFG_SERVER_TYPE" == "tem" ] || [ "$arg_type" == "tem" ]
then
	if [ "$arg_refresh" == "1" ]
	then
		err "Error: --refresh is not supported for tem"
		exit 1
	fi
	tem_update
	update_configs
	git_save_pull
else
	err "something went wrong :/"
	exit 1
fi

