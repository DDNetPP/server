#!/bin/bash
shopt -s extglob # used for trailing slashes globbing

if [ ! -f lib/lib.sh ]
then
    echo "Error: lib/lib.sh not found!"
    echo "make sure you are in the root of the server repo"
    exit 1
fi

source lib/lib.sh

maps_dir="${SCRIPT_ROOT}/maps"

function usage() {
	cat <<-EOF
	usage: ./lib/get_maps.sh [OPTION..]
	description:
	  interactively download teeworlds maps from differen sources
	options:
	  --output-dir DIRECTORY            where to save the maps to
	  --non-interactive                 errors instead of promting the user
	  --source SOURCE_NAME              where to download maps from
	example:
	  ./lib/get_maps.sh --non-interactive --output-dir maps --source "vanilla 0.7.1 release"
	EOF
}

SOURCE_OPTIONS=(
	"vanilla git"
	"vanilla 0.7.1 release"
	"vanilla 0.6.5 release"
	"heinrich5991 [BIG]"
	"ddnet [BIG]"
	"ddnet7 [BIG]"
	"KoG [BIG]"
	"ddnet++"
	"chiller"
	"zillyfng"
	"zillyfly"
	"ddnet-insta-06"
	"ddnet-insta-07"
	"Quit"
)

ARG_OUTPUT_DIR=''
ARG_SOURCE=''
ARG_NON_INTERACTIVE=0

function parse_args() {
	local arg
	while true
	do
		[ "$#" -eq 0 ] && break

		arg="$1"
		shift

		if [ "$arg" = "--help" ] || [ "$arg" = "-h" ] || [ "$arg" = "help" ]
		then
			usage
			exit 0
		elif [ "$arg" = "--output-dir" ]
		then
			ARG_OUTPUT_DIR="$1"
			shift
			if [ "$ARG_OUTPUT_DIR" = "" ]
			then
				err "--output-dir requires an argument"
				exit 1
			fi
			if [ "${ARG_OUTPUT_DIR::1}" != "/" ]
			then
				err "--output-dir has to point to an absolute path"
				exit 1
			fi
		elif [ "$arg" = "--source" ]
		then
			ARG_SOURCE="$1"
			shift
			if [ "$ARG_SOURCE" = "" ]
			then
				err "--source requires an argument"
				exit 1
			fi
			local source_option
			local found=0
			for source_option in "${SOURCE_OPTIONS[@]}"
			do
				if [ "$source_option" = "$ARG_SOURCE" ]
				then
					found=1
					break
				fi
			done
			if [ "$found" = 0 ]
			then
				err "Invalid source '$ARG_SOURCE' has to be one of those:"
				echo "${SOURCE_OPTIONS[*]}"
				exit 1
			fi
		elif [ "$arg" = "--non-interactive" ]
		then
			ARG_NON_INTERACTIVE=1
		else
			err "Error: invalid argument '$arg'"
			exit 1
		fi
	done
}

IFS=$'\n'
parse_args "$@"

function select_maps_dir() {
	if [ "$ARG_OUTPUT_DIR" != "" ]
	then
		maps_dir="$ARG_OUTPUT_DIR"
	elif [ "$ARG_NON_INTERACTIVE" = 1 ]
	then
		err "--non-interactive requires --output-dir to be set"
		exit 1
	else
		printf 'Select a map output directory:\n\n'
		read -r -e -i "$maps_dir" maps_dir
	fi
}

function download_web() {
	local url="$1"
	mkdir -p "$maps_dir" || exit 1
	cd "$maps_dir" || exit 1
	url="${url%%+(/)}" # strip trailing slash
	tmp="${url#*//}"
	num_dirs="$(echo "$tmp" | tr "/" "\\n" | wc -l)"
	num_dirs="$((num_dirs - 1))"
	wget -r -np -nH --cut-dirs="$num_dirs" -R index.html "$url/"
	cd "$SCRIPT_ROOT" || exit 1
}

function download_archive() {
	local archive_type="$1"
	local url="$2"
	local archive_name
	local tmp_maps_archive
	local tmp_maps_dir
	archive_name="${url##*/}"
	archive_name="$(basename "$archive_name" ".$archive_type")"
	tmp_maps_root="/tmp/ddpp_$USER"
	tmp_maps_archive="$tmp_maps_root/maps.archive"
	tmp_maps_dir="$tmp_maps_root/maps"
	mkdir -p "$tmp_maps_root" || exit 1
	mkdir -p "$maps_dir" || exit 1
	if [ -f "$tmp_maps_archive" ]
	then
		rm -rf "$tmp_maps_archive" || exit 1
	fi
	if [ -d "$tmp_maps_dir" ]
	then
		rm -rf "$tmp_maps_dir" || exit 1
	fi
	wget -O "$tmp_maps_archive" "$url"
	if [ "$archive_type" == "zip" ]
	then
		unzip "$tmp_maps_archive" -d "$tmp_maps_dir"
	elif [ "$archive_type" == "tar.gz" ]
	then
		tar -xvzf "$tmp_maps_archive" -C "$tmp_maps_root"
		mv "$tmp_maps_root/$archive_name" "$tmp_maps_dir" || exit 1
	elif [ "$archive_type" == "tar.xz" ]
	then
		tar -xf "$tmp_maps_archive" -C "$tmp_maps_root"
		mv "$tmp_maps_root/$archive_name" "$tmp_maps_dir" || exit 1
	else
		err "unsupported archive_type '$archive_type'"
		exit 1
	fi
	found=0
	cd "$tmp_maps_dir" || { err "failed to cd into '$dir'"; exit 1; }
	count="$(find . -name -maxdepth 1 '*.map' 2>/dev/null | wc -l)"
	if [ "$count" != 0 ]
	then
		log "found $count maps. copying ..."
		cp "$tmp_maps_dir"*.map "$maps_dir" || exit 1
		found=1
	fi
	# check one first subdir or data/maps to look for more maps
	dir="$(find . -type d -print | tail -n1)"
	if [ -d data/maps ]
	then
		dir=data/maps
	fi
	if [[ "$dir" != "" ]]
	then
		log "navigating to '$dir'"
		cd "$dir" || { err "failed to cd into '$dir'"; exit 1; }
		count="$(find . -name '*.map' 2>/dev/null | wc -l)"
		if [ "$count" != 0 ]
		then
			log "found $count maps. copying ..."
			cp "$tmp_maps_dir/$dir"/*.map "$maps_dir" || exit 1
			found=1
		fi
	fi
	if [ "$found" == "0" ]
	then
		err "did not find any maps in the zip file"
		err "url: $url"
		exit 1
	fi
	if [ -f "$tmp_maps_archive" ]
	then
		rm -rf "$tmp_maps_archive" || exit 1
	fi
	if [ -d "$tmp_maps_dir" ]
	then
		rm -rf "$tmp_maps_dir" || exit 1
	fi
	cd "$SCRIPT_ROOT" || exit 1
}

function download_git() {
	local url="$1"
	mkdir -p "$maps_dir" || exit 1
	if [ -d /tmp/YYY_maps/ ]
	then
		rm -rf /tmp/YYY_maps/ || exit 1
	fi
	git clone "$url" /tmp/YYY_maps || exit 1
	cp -r /tmp/YYY_maps/* "$maps_dir"
	if [ -d /tmp/YYY_maps/ ]
	then
		rm -rf /tmp/YYY_maps/ || exit 1
	fi
	cd "$SCRIPT_ROOT" || exit 1
}

# @param opt
function select_option() {
	local opt="$1"
	case $opt in
		"vanilla git")
			download_git https://github.com/teeworlds/teeworlds-maps
			return 0
			;;
		"vanilla 0.7.1 release")
			download_archive tar.gz https://github.com/teeworlds/teeworlds/releases/download/0.7.1/teeworlds-0.7.1-linux_x86_64.tar.gz
			return 0
			;;
		"vanilla 0.6.5 release")
			download_archive tar.xz https://downloads.teeworlds.com/teeworlds-0.6.5-linux_x86_64.tar.xz
			return 0
			;;
		"heinrich5991 [BIG]")
			download_web http://heinrich5991.de/teeworlds/maps/maps/
			return 0
			;;
		"ddnet [BIG]")
			download_git https://github.com/ddnet/ddnet-maps
			return 0
			;;
		"ddnet7 [BIG]")
			download_archive zip https://maps.ddnet.tw/compilations/maps7.zip
			return 0
			;;
		"KoG [BIG]")
			download_archive tar.gz https://qshar.com/maps.tar.gz
			return 0
			;;
		"ddnet++")
			download_git https://github.com/DDNetPP/maps
			return 0
			;;
		"chiller")
			download_git https://github.com/ChillerTW/GitMaps
			return 0
			;;
		"zillyfng")
			download_git https://github.com/ZillyFng/solofng-maps
			return 0
			;;
		"zillyfly")
			download_git https://github.com/ZillyFly/fly-maps
			return 0
			;;
		"ddnet-insta-06")
			download_git https://github.com/ddnet-insta/maps-06
			return 0
			;;
		"ddnet-insta-07")
			download_git https://github.com/ddnet-insta/maps-07
			return 0
			;;
		"Quit")
			return 0
			;;
		*) echo "invalid option ${REPLY:-$opt}";;
	esac
	return 1
}

function menu() {
	check_server_dir
	select_maps_dir
	if [[ -d "$maps_dir" ]] && [[ "$(ls "$maps_dir")" != "" ]]
	then
		num_maps="$(find "$maps_dir" | wc -l)"
		wrn "You already have $num_maps maps in:"
		wrn "$maps_dir"
		echo "do you want to overwrite/add to current map pool? [y/N]"
		if [ "$ARG_NON_INTERACTIVE" = 1 ]
		then
			err "aborting because --non-interactive is set"
			exit 1
		fi
		read -n 1 -rp "" inp
		echo ""
		if ! [[ $inp =~ ^[Yy]$ ]]
		then
			echo "Aborting script..."
			exit
		fi
	fi
	PS3='Please enter your choice: '
	if [ "$ARG_SOURCE" != "" ]
	then
		select_option "$ARG_SOURCE"
	elif [ "$ARG_NON_INTERACTIVE" = 1 ]
	then
		err "--non-interactive requires --source to be set"
		exit 1
	else
		select opt in "${SOURCE_OPTIONS[@]}"
		do
			select_option "$opt" && break
		done
	fi
}

menu

