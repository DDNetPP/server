#!/bin/bash

# gets overwritten if patches are applied
# absolute paths to the patch files
# that were succesfully applied on last
# apply_git_patches() run
_APPLIED_GIT_PATCHES=()

_patch_dir_absolute() {
	[ "$CFG_GIT_PATCHES_DIR" = "" ] && return
	if [ "${CFG_GIT_PACTHES_DIR::1}" = / ]
	then
		printf '%s' "$CFG_GIT_PATCHES_DIR"
	else
		printf '%s/%s' "$SCRIPT_ROOT" "$CFG_GIT_PATCHES_DIR"
	fi
}

_apply_git_patch_files() {
	# patches can be grouped in directories
	# if a directory is found it applies
	# the patches in alphabetical order
	# until one applies without conflicts
	# patches at the root are all applied
	# example patches folder:
	#
	# patches/
	# ├── add_animals.patch
	# ├── add_debug.patch
	# └── fix_snap_bug
	#     ├── ddnet.patch
	#     └── teeworlds.patch
	#

	local patch_dir_abs
	patch_dir_abs="$(_patch_dir_absolute)"
	local patch_dir
	local patch_file
	# only one patch per dir needed
	for patch_dir in "$patch_dir_abs"/*/
	do
		[ ! -d "$patch_dir" ] && continue

		local patch_applied=0
		for patch_file in "$patch_dir"/*.patch
		do
			[ "$patch_applied" = 1 ] && continue
			[ ! -f "$patch_file" ] && continue

			if git apply "$patch_file"
			then
				log "applied patch '$patch_file'"
				_APPLIED_GIT_PATCHES+=("$patch_file")
				patch_applied=1
			fi
		done
		if [ "$patch_applied" = 0 ]
		then
			wrn "WARNING: failed to apply patch '$patch_dir'"
		fi
	done
	# root level patches are single files
	for patch_file in "$patch_dir_abs"/*.patch
	do
		[ ! -f "$patch_file" ] && continue

		if git apply "$patch_file"
		then
			log "applied patch '$patch_file'"
			_APPLIED_GIT_PATCHES+=("$patch_file")
		else
			wrn "WARNING: failed to apply patch '$patch_file'"
		fi
	done
}

_save_applied_patches() {
	mkdir -p "$SCRIPT_ROOT/lib/var"
	printf '%s' "${_APPLIED_GIT_PATCHES[*]}" > "$SCRIPT_ROOT/lib/var/applied_git_patches.txt"
}

get_applied_git_patches() {
	mkdir -p "$SCRIPT_ROOT/lib/var"
	[ ! -f "$SCRIPT_ROOT/lib/var/applied_git_patches.txt" ] && return
	cat "$SCRIPT_ROOT/lib/var/applied_git_patches.txt"
}

reverse_git_patches() {
	pushd "$CFG_GIT_PATH_MOD" >/dev/null || exit 1
	local patch_file
	for patch_file in "${_APPLIED_GIT_PATCHES[@]}"
	do
		if ! git apply --reverse "$patch_file"
		then
			wrn "WARNING: failed to reverse patch '$patch_file'"
		fi
	done
	popd >/dev/null || exit 1 # CFG_GIT_PATH_MOD
}

apply_git_patches() {
	_APPLIED_GIT_PATCHES=()
	local patch_dir_abs
	patch_dir_abs="$(_patch_dir_absolute)"
	[ "$patch_dir_abs" = "" ] && return
	if [ ! -d "$patch_dir_abs" ] 
	then
		# if the user set a custom git patches dir
		# we check its existance
		# if it is the default dir then the user might also
		# not be using batches at all so we silent ignore it
		if [ ! "$CFG_GIT_PATCHES_DIR" = patches ]
		then
			wrn "WARNING: git patches dir '$patch_dir_abs' not found"
		fi
		return
	fi

	pushd "$CFG_GIT_PATH_MOD" >/dev/null || exit 1
	_apply_git_patch_files
	_save_applied_patches
	popd >/dev/null || exit 1 # CFG_GIT_PATH_MOD
}

