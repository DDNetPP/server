#!/bin/bash

# https://github.com/dylanaraps/pure-bash-bible#reverse-an-array

# Enabling extdebug allows access to the BASH_ARGV array which stores the current function’s arguments in reverse.
# CAVEAT: Requires shopt -s compat44 in bash 5.0+.

reverse_array() {
	# Usage: reverse_array "array"
	shopt -s extdebug
	_f()(printf '%s\n' "${BASH_ARGV[@]}"); _f "$@"
	shopt -u extdebug
}

