#!/bin/bash

# COMMIT_HASH=yourhash source lib/env_san.sh

lib_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ "$lib_dir" = "" ]
then
	echo "Error: failed to get lib dir"
	exit 1
fi

if [ ! -d "$lib_dir" ]
then
	echo "Error: lib dir '$lib_dir' is not a directory"
	exit 1
fi

assert_file() {
	[ -f "$1" ] && return
	echo "Error: file not found '$1'"
	exit 1
}

assert_dir() {
	[ -d "$1" ] && return
	echo "Error: directory not found '$1'"
	exit 1
}

log_dir="$lib_dir"/../logs
logfile="$log_dir"/SAN_"${COMMIT_HASH:-null}"_"$(date '+%F_%H-%M')"

assert_file "$lib_dir"/supp/ubsan.supp
assert_file "$lib_dir"/supp/lsan.supp
assert_dir "$log_dir"

set_vars() {
	if [ ! -x "$(command -v clang++)" ]
	then
		echo "[!] Warning: trying to to use sanitizer env but clang++ is not installed"
		echo "             check your env_runtime and env_build in your settings.cfg"
		echo "             make sure clang++ is in PATH"
		echo ""
		echo "             ignoring the current env! The sanitizer will not be activated to avoid build errors"
		echo ""
		return
	fi

	# runtime
	export UBSAN_OPTIONS=suppressions="$lib_dir"/supp/ubsan.supp:log_path="$logfile":print_stacktrace=1:halt_on_errors=0
	export ASAN_OPTIONS=log_path="$logfile":print_stacktrace=1:check_initialization_order=1:detect_leaks=1:halt_on_errors=0
	export LSAN_OPTIONS=suppressions="$lib_dir"/supp/lsan.supp

	# compile time
	export CC=clang
	export CXX=clang++
	export CXXFLAGS="-fsanitize=address,undefined -fsanitize-recover=address,undefined -fno-omit-frame-pointer"
	export CFLAGS="-fsanitize=address,undefined -fsanitize-recover=address,undefined -fno-omit-frame-pointer"
}

set_vars
