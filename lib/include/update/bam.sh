#!/bin/bash

function bam4_refresh_teeworlds_binary() {
	local bin_path_src="$CFG_GIT_PATH_MOD/$CFG_COMPILED_BIN"
	if [ ! -f "$bin_path_src" ]
	then
		err "Error: binary not found try ./update.sh"
		err "       $bin_path_src"
		return
	fi
	cp \
		"$bin_path_src" \
		"${SCRIPT_ROOT}/${CFG_BIN}"
}

function bam5_refresh_teeworlds_binary() {
	err "Not supported bam4"
	exit 1
}


function bam_update_teeworlds() {
	# bam_update \
	# 	"$CFG_GIT_PATH_MOD" \
	# 	"$CFG_FORCE_PULL" \
	# 	"$CFG_GIT_BRANCH" \
	# 	"$CFG_GIT_COMMIT" \
	# 	CFG_CMAKE_FLAGS \
	# 	"$CFG_COMPILED_BIN" \
	# 	teeworlds \
	# 	"$@"

	local bam_version="$1"

	local pointer_bam_flags="CFG_BAM_FLAGS" # has to be name of an array variable
	# https://www.shellcheck.net/wiki/SC1087
	local pointer_bam_flags_arr="${pointer_bam_flags}[@]"
	local arg_bam_flags=("${!pointer_bam_flags_arr}") # parameter expansion

	if [ "$(vartype "$pointer_bam_flags")" != "ARRAY" ]
	then
		vartype "$pointer_bam_flags"
		err "ERROR: bam_update argument <bam flags> has to be an array"
		exit 1
	fi

	cd "$CFG_GIT_PATH_MOD" || exit 1

	apply_git_patches
	local build_cmd="$CFG_BAM_BIN ${arg_bam_flags[*]}"
	bash -c "set -euo pipefail;$build_cmd" || \
		{ err --log "build failed (bam)"; }
	reverse_git_patches

	if [ "$bam_version" == "4" ]
	then
		bam4_refresh_teeworlds_binary
	else
		bam5_refresh_teeworlds_binary
	fi

	update_configs
}

