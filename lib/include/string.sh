#!/bin/bash

# https://stackoverflow.com/a/3352015/6287070
trim() {
	local var="$*"
	# remove leading whitespace characters
	var="${var#"${var%%[![:space:]]*}"}"
	# remove trailing whitespace characters
	var="${var%"${var##*[![:space:]]}"}"
	printf '%s' "$var"
}

