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
