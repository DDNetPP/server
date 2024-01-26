#!/bin/bash

if [ ! -f lib/lib.sh ]
then
    echo "Error: lib/lib.sh not found!"
    echo "make sure you are in the root of the server repo"
    exit
fi

source lib/lib.sh

source lib/include/update/vartype.sh
source lib/include/update/cmake.sh
source lib/include/update/custom.sh
source lib/include/update/bam.sh

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
	elif [ "$arg" == "--force" ] || [ "$arg" == "-f" ]
	then
		# gets passed on
		test
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
	local map_name
	for map_name in "$CFG_GIT_ROOT"/maps-scripts/*/themes
	do
		map_name="${map_name%/*}" # cut off /themes at the end
		map_name="$(basename "$map_name")" # get folder name for examle BlmapChill
		if [ -f ./maps/"$map_name".map ]
		then
			OldMapHashes["$map_name"]="$(sha1sum ./maps/"$map_name".map | cut -d' ' -f1)"
		fi
	done
}
function map_themes_post() {
	if [ ! -d "$CFG_GIT_ROOT"/maps-scripts ]
	then
		return
	fi
	# expects the following folder structure
	# https://github.com/DDNetPP/maps-scripts
	local map_name
	local t
	for map_name in "$CFG_GIT_ROOT"/maps-scripts/*/themes
	do
		map_name="${map_name%/*}" # cut off /themes at the end
		map_name="$(basename "$map_name")" # get folder name for examle BlmapChill
		log "themes for  $map_name"
		if [ -f ./maps/"$map_name".map ]
		then
			if [ "${OldMapHashes["$map_name"]}" != "$(sha1sum ./maps/"$map_name".map | cut -d' ' -f1)" ]
			then
				log "map '$map_name' updated generating new themes ..."
				log "  old: ${OldMapHashes["$map_name"]}"
				log "  new: $(sha1sum ./maps/"$map_name".map | cut -d' ' -f1)"
				for t in "$CFG_GIT_ROOT"/maps-scripts/"$map_name"/themes/*.py
				do
					log "generating '$(basename "$t" .py)' theme for '$map_name' ..."
					mkdir -p ./designs/"$map_name"
					"$t" ./maps/"$map_name".map ./designs/"$map_name"/"$(basename "$t" .py)".map
				done
			fi
		fi
	done
}
function update_lua() {
	[[ -d lua ]] || return
	[[ -d lua/.git ]] || return

	log "checking for lua/ updates"
	pushd lua || return
	git_save_pull
	popd || return
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
	update_lua
elif [ "$CFG_SERVER_TYPE" == "teeworlds" ] || [ "$arg_type" == "teeworlds" ]
then
	if [ "$arg_refresh" == "1" ]
	then
		cmake_refresh_teeworlds_binary
		exit 0
	fi
	map_themes_pre
	if [ "$CFG_BUILD_SYSTEM" == "cmake" ]
	then
		cmake_update_teeworlds "$@"
	elif [ "$CFG_BUILD_SYSTEM" == "bam" ]
	then
		bam_update_teeworlds 5 "$@"
	elif [ "$CFG_BUILD_SYSTEM" == "bam4" ]
	then
		bam_update_teeworlds 4 "$@"
	elif [ "$CFG_BUILD_SYSTEM" == "custom" ]
	then
		custom_update_teeworlds "$@"
	else
		err "Unsupported build system: $CFG_BUILD_SYSTEM"
		exit 1
	fi
	map_themes_post
	git_save_pull
	update_lua
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

