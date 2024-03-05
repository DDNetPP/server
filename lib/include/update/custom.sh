#!/bin/bash

function custom_update_teeworlds() {
	# cmake_update \
	# 	"$CFG_GIT_PATH_MOD" \
	# 	"$CFG_FORCE_PULL" \
	# 	"$CFG_GIT_BRANCH" \
	# 	"$CFG_GIT_COMMIT" \
	# 	CFG_CMAKE_FLAGS \
	# 	"$CFG_COMPILED_BIN" \
	# 	teeworlds \
	# 	"$@"

	cd "$CFG_GIT_PATH_MOD" || exit 1

	apply_git_patches
	"$CFG_CUSTOM_BUILD_CMD" || exit 1
	reverse_git_patches

	update_configs
}

