#!/bin/bash

# vartype: written by Marco and shellchecked by ChillerDragon
# https://stackoverflow.com/a/42877229
function vartype() {
	local var
	var=$( declare -p "$1" )
	local reg='^declare -n [^=]+=\"([^\"]+)\"$'
	while [[ $var =~ $reg ]]; do
		var=$( declare -p "${BASH_REMATCH[1]}" )
	done

	case "${var#declare -}" in
	a*)
		echo "ARRAY"
		;;
	A*)
		echo "HASH"
		;;
	i*)
		echo "INT"
		;;
	x*)
		echo "EXPORT"
		;;
	*)
		echo "OTHER"
		;;
	esac
}

function cmake_refresh_teeworlds_binary() {
	if [ ! -f "$CFG_GIT_PATH_MOD/build/$CFG_COMPILED_BIN" ]
	then
		err "Error: binary not found try ./update.sh"
		err "       $CFG_GIT_PATH_MOD/build/$CFG_COMPILED_BIN"
		return
	fi
	cp \
		"$CFG_GIT_PATH_MOD/build/$CFG_COMPILED_BIN" \
		"${SCRIPT_ROOT}/${CFG_BIN}"
}

function cmake_update_teeworlds() {
	cmake_update \
		"$CFG_GIT_PATH_MOD" \
		"$CFG_FORCE_PULL" \
		"$CFG_GIT_BRANCH" \
		"$CFG_GIT_COMMIT" \
		CFG_CMAKE_FLAGS \
		"$CFG_COMPILED_BIN" \
		teeworlds \
		"$@"
}

function cmake_update_bot() {
	cmake_update \
		"$CFG_GIT_PATH_BOT" \
		"" \
		"" \
		"" \
		CFG_CMAKE_FLAGS \
		"$CFG_COMPILED_BIN_BOT" \
		bot \
		"$@"
}

function cmake_update() {
	local arg_git_path="$1"
	local arg_force_pull="$2"
	local arg_git_branch="$3"
	local arg_git_commit="$4"
	local pointer_cmake_flags="$5" # has to be name of an array variable
	local pointer_cmake_flags_arr="$5[@]"
	local arg_cmake_flags=("${!pointer_cmake_flags_arr}") # parameter expansion
	local arg_compiled_bin="$6"
	local arg_type="$7" # teeworlds or bot
	local arg_args="$8" # --force to ignore dirty source tree
	if [ "$#" != "7" ] && [ "$#" != "8" ]
	then
		err "ERROR: cmake_update expected 8 or 9 arguments but got $#"
		err ""
		tput bold
		err "       cmake_update <git path> <force pull> <git branch>"
		err "                    <git commit> <cmake flags> <compiled bin>"
		err "                    <type> [--force]"
		tput sgr0
		exit 1
	elif [[ ! "$arg_type" =~ (teeworlds|bot) ]]
	then
		err "ERROR: cmake_update invalid type '$arg_type'"
		exit 1
	elif [ "$(vartype "$pointer_cmake_flags")" != "ARRAY" ]
	then
		err "ERROR: cmake_update argument <cmake flags> has to be an array"
		exit 1
	elif [ "$arg_git_path" == "" ]
	then
		err "ERROR: cmake_update argument <git path> can not be empty"
		exit 1
	fi
	if [ "$arg_args" == "-f" ] || [ "$arg_args" == "--force" ]
	then
		arg_args=--force
	elif [ "$arg_args" != "" ]
	then
		err "ERROR: arg_args can only be --force or -f"
		exit 1
	fi

	install_dep make
	install_dep cmake
	install_dep git

	mkdir -p maps || { err "Error: creating dir maps/"; exit 1; }
	mkdir -p logs || { err "Error: creating dir logs/"; exit 1; }
	mkdir -p bin || { err "Error: creating dir bin/"; exit 1; }
	if [ "$arg_type" == "bot" ]
	then
		mkdir -p bin/bot || { err "Error: creating dir bin/bot/"; exit 1; }
	fi
	cd "$arg_git_path" || { err "Could not enter git directory"; exit 1; }
	bin_old_commit="$(git rev-parse HEAD)"
	if [ "$bin_old_commit" == "" ]
	then
		err "could not determine current commit"
		bin_old_commit=invalid
	fi
	git pull || { git_pull=fail; }
	if [[ -n $(git status -s) ]] || [[ "$git_pull" == "fail" ]]
	then
		git submodule update
		if [ "$arg_force_pull" == "1" ] || is_cfg CFG_GIT_FORCE_PULL
		then
			upstream="$(git for-each-ref --format='%(upstream:short)' "$(git symbolic-ref -q HEAD)")"
			wrn "Warning: git status not clean after pull"
			wrn "         forcing a hard reset to '$upstream'"
			git reset --hard "$upstream"
		fi
	fi
	if [[ -n $(git status -s) ]] && [[ "$arg_args" != "--force" ]]
	then
		err --log "Error: updating the git repo failed"
		err       "       cd $arg_git_path"
		err       "       git status"
		err       "       $(tput bold)./update.sh --force$(tput sgr0) to ignore"
		exit 1
	fi
	current_branch="$(git rev-parse --abbrev-ref HEAD)"
	if [ "$arg_git_branch" != "" ]
	then
		log "checking out branch specified in cfg $arg_git_branch ..."
		git add . || exit 1
		git reset --hard || exit 1
		git checkout "$arg_git_branch"
		git pull
	fi
	if [ "$arg_git_commit" != "" ]
	then
		log "checking out commit specified in cfg $arg_git_commit ..."
		git checkout "$arg_git_commit"
	fi
	if [ "$CFG_GITPATH_ANTIBOT" != "" ]
	then
		log "patching antibot ..."
		(
			cd "$CFG_GITPATH_ANTIBOT" || exit 1
			git pull
		)
		cp "$CFG_GITPATH_ANTIBOT"/*.h src/antibot/
		cp "$CFG_GITPATH_ANTIBOT"/*.cpp src/antibot/
	fi
	bin_commit="$(git rev-parse HEAD)"
	local cmake_cache="$SCRIPT_ROOT/lib/tmp/cmake_flags.txt"
	if [ -f "$cmake_cache" ]
	then
		if [ "${arg_cmake_flags[*]}" != "$(cat "$cmake_cache")" ]
		then
			log "cmake flags changed:"
			log " old='$(cat "$cmake_cache")'"
			log " new='${arg_cmake_flags[*]}'"
			log "deleting build directory ..."
			rm -rf build
		fi
	fi
	echo "${arg_cmake_flags[*]}" > "$cmake_cache"
	mkdir -p build || { err "Error: creating dir build/"; exit 1; }
	cd build || { err "Could not enter build/ directory"; exit 1; }
	branch="$(git branch | sed -n '/\* /s///p')"

	local build_fail=0
	local build_cmd="$CFG_ENV_BUILD cmake .. ${arg_cmake_flags[*]}"
	log "$(tput bold)$build_cmd$(tput sgr0)"
	eval "$build_cmd" || \
		{ err --log "build failed at $branch $bin_commit (cmake)"; build_fail=1; }
	if [ "$build_fail" == "0" ]
	then
		make "-j$(get_cores)" || { err --log "build failed at $branch $(git rev-parse HEAD) (make)"; build_fail=1; }
	fi
	if [ "$arg_git_commit" != "" ] || [ "$arg_git_branch" != "" ]
	then
		git add .. || exit 1
		git reset --hard || exit 1
		git checkout "$current_branch"
	fi
	if [ "$CFG_GITPATH_ANTIBOT" != "" ]
	then
		log "cleaning up antibot patch ..."
		git add ../src/antibot
		git reset --hard HEAD
		if [ -f "$CFG_GITPATH_ANTIBOT"/libantibot.so ]
		then
			log "move libantibot.so ..."
			cp "$CFG_GITPATH_ANTIBOT"/libantibot.so .
		fi
	fi
	if [ "$build_fail" == "1" ]
	then
		err --log "build failed."
		exit 1
	fi
	if [ ! -f "$arg_compiled_bin" ]
	then
		err "Binary not found is your config correct?"
		err "Expected binary name '$arg_compiled_bin'"
		err "and only found those files:"
		ls --color=always
		exit 1
	fi

	(
		cd "${SCRIPT_ROOT}" || exit 1
		generate_tw_syntax --force
	)
	if [ "$arg_type" == "teeworlds" ]
	then
		if [ -f "${SCRIPT_ROOT}/${CFG_BIN}" ]
		then
			log "creating backup of old binary at bin/backup"
			mkdir -p "${SCRIPT_ROOT}/bin/backup"
			cp "${SCRIPT_ROOT}/${CFG_BIN}" "${SCRIPT_ROOT}/bin/backup/$bin_old_commit"
		fi
		cmake_refresh_teeworlds_binary

		if is_cfg CFG_COPY_MAPS_FROM_MOD
		then
			num_maps="$(find ./data/maps -maxdepth 1 -name '*.map' 2>/dev/null | wc -l)"
			if [ "$num_maps" != 0 ]
			then
				log "copying $num_maps maps from source directory ..."
				cp data/maps/*.map "${SCRIPT_ROOT}/maps"
			fi
		fi
		update_configs

		if is_cfg CFG_TEST_RUN
		then
			log "test if server can start ..."
			cd "${SCRIPT_ROOT}" || exit 1
			if ! ./"${CFG_BIN}" "sv_port $CFG_TEST_RUN_PORT;status;shutdown"
			then
				err --log "failed to run server built with $bin_commit"
				if [ -f "${SCRIPT_ROOT}/bin/backup/$bin_old_commit" ]
				then
					wrn "restoring backup binary ..."
					mv "${SCRIPT_ROOT}/bin/backup/$bin_old_commit" "${SCRIPT_ROOT}/${CFG_BIN}"
				fi
			fi
		fi
	elif [ "$arg_type" == "bot" ]
	then
		cp "$arg_compiled_bin" "${SCRIPT_ROOT}/bin/bot/" || exit 1
	fi

	cd "${SCRIPT_ROOT}" || exit 1
}


