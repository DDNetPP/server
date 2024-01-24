#!/bin/bash

function storage_get_save_path() {
	if [ ! -f storage.cfg ]
	then
		echo "$HOME/.teeworlds/"
		return
	fi
	local dir
	dir="$(grep '^add_path \$' storage.cfg |
		head -n1 | cut -d'$' -f2-)"
	if [ "$dir" == "CURRENTDIR" ]
	then
		echo "."
		return
	fi
	# TODO: error or something
	# 	also do support custom non $ paths
	echo "$HOME/.teeworlds/"
}

function storage_paths() {
	if [ ! -f storage.cfg ]
	then
		echo "$HOME/.teeworlds/"
		echo "."
		return
	fi
	local dir
	while read -r dir
	do
		# shellcheck disable=SC2016
		if [ "$dir" == '$USERDIR' ]
		then
			echo "$HOME/.teeworlds/"
		elif [ "$dir" == '$CURRENTDIR' ]
		then
			echo "."
		elif [ "$dir" == '$DATADIR' ]
		then
			# TODO: pick correct one here
			echo "/usr/share/ddnet/data"
			echo "/usr/share/teeworlds/data"
		else
			echo "$dir"
		fi
	done < <(grep '^add_path ' storage.cfg | cut -d' ' -f2-)
}

