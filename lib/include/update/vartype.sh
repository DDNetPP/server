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

