#!/bin/bash


# while ! lock_build
# do
# 	wrn "WARNING: failed to lock build (retrying in one second)"
# 	sleep 1
# done
#
# # do build
#
# unlock_build

BUILD_LOCKFILE=/tmp/"$USER"_ddpp_build_lock.txt

###################
# internal helpers

function _meta_lock() {
	# meta lock file to avoid multiple processes
	# writing to the same build lock file
	if [ -f "$BUILD_LOCKFILE".lock ]
	then
		wrn "WARNING: failed to lock build. The lock file is locked."
		return 1
	fi
	printf '%s %s\n' "$SERVER_UUID" "$$" > "$BUILD_LOCKFILE".lock
	sleep 0.2
	if ! grep -q "$SERVER_UUID $$" "$BUILD_LOCKFILE".lock
	then
		wrn "WARNING: failed to lock build. Failed to lock the lock file."
		return 1
	fi
	return 0
}

function _meta_unlock() {
	if ! grep -q "$SERVER_UUID $$" "$BUILD_LOCKFILE".lock
	then
		wrn "WARNING: failed to unlock the build lock meta lockfile"
		return 1
	fi
	rm "$BUILD_LOCKFILE".lock
	return 0
}

function _remove_build_lock() {
	local pattern="$1"
	_meta_lock || return 1

	grep -v "$pattern" "$BUILD_LOCKFILE" > "$BUILD_LOCKFILE".tmp
	mv "$BUILD_LOCKFILE".tmp "$BUILD_LOCKFILE"

	_meta_unlock || return 1
}

function _cleanup_stale_locks() {
	# meta lock
	local pid
	if [ -f "$BUILD_LOCKFILE".lock ]
	then
		pid="$(awk '{ print $2 }' "$BUILD_LOCKFILE".lock | head -n1)"
		if [ "$pid" = "" ]
		then
			# can be a race condition we should probably sleep a random amount of time here
			# and if it is still an empty file remove it
			wrn "WARNING: there is a meta build lock file but no pid owns it"
		else
			if ! ps -p "$pid" >/dev/null
			then
				wrn "WARNING: the pid $pid holding the meta lock is not running"
				wrn "         removed the meta lock ..."
				rm "$BUILD_LOCKFILE".lock
			fi
		fi
	fi

	local path
	local uuid
	local lock_entry

	# build lock
	while read -r lock_entry
	do
		path="$(printf '%s\n' "$lock_entry" | awk '{ print $1 }')"
		uuid="$(printf '%s\n' "$lock_entry" | awk '{ print $2 }')"
		pid="$(printf '%s\n' "$lock_entry" | awk '{ print $3 }')"
		if ! ps "$pid" >/dev/null
		then
			wrn "WARNING: the pid $pid holding the build lock is not running"
			wrn "         removed the lock entry ..."

			_remove_build_lock "^$path $uuid $pid "
		fi
	done < "$BUILD_LOCKFILE"
}

#############
# public api

function is_build_locked() {
	touch "$BUILD_LOCKFILE"
	if grep -q "^$CFG_GIT_PATH_MOD " "$BUILD_LOCKFILE"
	then
		_cleanup_stale_locks
		return 0
	fi
	return 1
}

function lock_build() {
	if is_build_locked
	then
		wrn "WARNING: failed to lock build. It is already locked"
		return 1
	fi

	_meta_lock || return 1
	# lock the build
	printf '%s %s %s %s\n' "$CFG_GIT_PATH_MOD" "$SERVER_UUID" "$$" "$(date '+%s')" >> "$BUILD_LOCKFILE"
	_meta_unlock || return 1
}

function unlock_build() {
	# remove our lock entry
	_remove_build_lock "^$CFG_GIT_PATH_MOD $SERVER_UUID $$ " || return 1
}

