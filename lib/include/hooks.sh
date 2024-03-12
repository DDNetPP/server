#!/bin/bash

USER_HOOK_NAMES=(
	before_compile
)

# create a folder called hooks/
# and then in there a folder with the hook name
# so for example hooks/before_compile
# then put your shell scripts in there
# they have to end with .sh and will be executed with bash
# they are run LC_ALL=C sorted order
#
# sample folder structure:
#
# hooks/
# └── before_compile
#     ├── 01-foo.sh
#     └── 02-foo.sh

run_hook() {
	local hook_name="$1"
	[ -d "$SCRIPT_ROOT/hooks" ] || return
	[ -d "$SCRIPT_ROOT/hooks/$hook_name" ] || return

	local hook_script
	while read -r hook_script
	do
		log "running hook script $hook_script"
		if ! bash "$hook_script"
		then
			err "Error: failed to run $hook_script"
		fi
	done < <(find "$SCRIPT_ROOT/hooks/$hook_name/" -name "*.sh" | LC_ALL=C sort)
}

register_hook() {
	local hook_name="$1"
	local hook
	local found=0
	for hook in "${USER_HOOK_NAMES[@]}"
	do
		if [ "$hook_name" = "$hook" ]
		then
			found=1
			break
		fi
	done
	if [ "$found" = 0 ]
	then
		err "Error: invalid hook name '$hook_name'"
		exit 1
	fi

	run_hook "$hook_name"
}

# is run before the compile step
# the current working directory should be
# the source of the code repository (not the build folder yet)
register_hook_before_compile() {
	register_hook before_compile
}

