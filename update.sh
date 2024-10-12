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

print_default() {
	if [ "$CFG_SERVER_TYPE" == "$1" ]
	then
		tput bold
		printf "(default)"
		tput sgr0
	fi
}

tem_update() {
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

map_themes_pre() {
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
map_themes_post() {
	if [ ! -d "$CFG_GIT_ROOT"/maps-scripts ]
	then
		return
	fi
	# expects the following folder structure fro $CFG_GIT_ROOT/maps-scripts
	# https://github.com/DDNetPP/maps-scripts
	#
	# and also supports ./designs being a maps repo like this
	# https://github.com/fddrace/maps-themes
	# where the generated themes will auto uploaded
	# and the plain mapfiles will be auto pulled
	if [ -d ./designs/.git ]
	then
		pushd ./designs/ > /dev/null || exit 1
		git_save_pull
		popd > /dev/null || exit 1
	fi
	local map_name
	local t
	local updated_themes=0
	for map_name in "$CFG_GIT_ROOT"/maps-scripts/*/themes
	do
		map_name="${map_name%/*}" # cut off /themes at the end
		map_name="$(basename "$map_name")" # get folder name for examle BlmapChill
		log "themes for $map_name"
		if [ -f ./maps/"$map_name".map ]
		then
			if [ "${OldMapHashes["$map_name"]}" != "$(sha1sum ./maps/"$map_name".map | cut -d' ' -f1)" ]
			then
				local version_script
				map_version=null
				version_script="$CFG_GIT_ROOT"/maps-scripts/"$map_name"/print_version.py
				log "map '$map_name' updated generating new themes ..."
				log "  old: ${OldMapHashes["$map_name"]}"
				log "  new: $(sha1sum ./maps/"$map_name".map | cut -d' ' -f1)"
				if [[ -f "$version_script" ]]
				then
					map_version="$($version_script ./maps/"$map_name".map)"
					log "  version: $map_version"
				fi
				for t in "$CFG_GIT_ROOT"/maps-scripts/"$map_name"/themes/*.py
				do
					local theme_name
					theme_name="$(basename "$t" .py)"
					log "generating '$theme_name' theme for '$map_name' ..."
					mkdir -p ./designs/"$map_name"
					"$t" ./maps/"$map_name".map ./designs/"$map_name"/"$theme_name".map

					updated_themes=1
					if [ -d ./designs/.git ]
					then
						pushd ./designs/ > /dev/null || exit 1
						git add ./"$map_name"/"$theme_name".map
						git commit -m "Updated map $map_name theme $theme_name to version $map_version"
						popd > /dev/null || exit 1
					fi
				done
			fi
		fi
	done
	if [ "$updated_themes" == "1" ] && [ -d ./designs/.git ]
	then
		pushd ./designs/ > /dev/null || exit 1
		git push
		popd > /dev/null || exit 1
	fi
}
update_non_git_module_sub_repos() {
	if ! is_cfg CFG_PULL_GIT_SUB_REPOS
	then
		return
	fi

	cd "$CFG_GIT_PATH_MOD" || exit 1
	local sub_repo
	while read -r sub_repo
	do
		[ -d "$sub_repo" ] || continue

		log "found sub repo $sub_repo"
		(
			cd "$sub_repo" || exit 1
			git_save_pull
		)
	done < <(find src -maxdepth 3 -name ".git" | rev | cut -c 5- | rev)
}
update_lua() {
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

	while ! lock_build
	do
		wrn "WARNING: the build is locked by another process"
		wrn "         waiting for the lock to release ..."
		sleep 10
	done

	map_themes_pre
	update_non_git_module_sub_repos
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
		unlock_build
		err "Unsupported build system: $CFG_BUILD_SYSTEM"
		exit 1
	fi
	map_themes_post
	git_save_pull
	update_lua

	unlock_build
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

