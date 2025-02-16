#!/bin/bash

# download/build new antibot from git repo
# there are different formats supported that provide antibot
# and this script will detect which format to use based on the
# antibot repository given in the config as gitpath_antibot=xxx
#
# supported antibot repo formats:
#
# - standalone built from source (recommended)
#   the repository is expected to contain a Makefile
#   and be able to compile on its own
#   the resulting libantibot.so is then copied to the runtime path
#   have a look at antibob for an example of such a repository
#   https://github.com/ChillerDragon/antibob
# - source code patched into the server
#   if no standalone is detected it is assumed to be a patch repo
#   that has to be integrated into the server code
#   there have to be .cpp and .h files AT THE ROOT of
#   the gitpath_antibot
#   these will be copied during build into the servers codebase
#   to src/antibot
# - binary
#   if the first two formats are not detected and there is a
#   libantibot.so AT THE ROOT of the gitpath_antibot
#   then it will be used as is
function update_antibot() {
	if [ "$CFG_GITPATH_ANTIBOT" = "" ]
	then
		return
	fi

	log "updating antibot ..."
	(
		cd "$CFG_GITPATH_ANTIBOT" || exit 1
		git_save_pull
	) || exit 1

	if [ -f "$CFG_GITPATH_ANTIBOT/Makefile" ]
	then
		log "detected antibot format: standalone"
		_antibot_format_standalone
	elif compgen -G "$CFG_GITPATH_ANTIBOT/*.{h,cpp}" > /dev/null
	then
		log "detected antibot format: source patches"
		_antibot_format_source_patches
	else
		log "detected antibot format: binary"
		_antibot_format_binary
	fi
}

function _antibot_format_standalone() {
	(
		cd "$CFG_GITPATH_ANTIBOT" || exit 1
		log -n "compiling standalone antibot with make .. "

		build_log="/tmp/${USER}_ddpp_antibot_build_$$.log"
		if ! make DDNET_DIR="$CFG_GIT_PATH_MOD" &> "$build_log"
		then
			log_status_error
			cat "$build_log"
			rm "$build_log"
			err "Error: building antibot with make failed"
			exit 1
		fi
		rm "$build_log"
		log_status_ok

		if [ ! -f "$CFG_GITPATH_ANTIBOT"/libantibot.so ]
		then
			err "Error: antibot make passed but did not produce a libantibot.so file"
			exit 1
		fi
	) || exit 1
}

function _antibot_format_source_patches() {
	# this is called from cmake.sh which is currently
	# in the server source directory
	log "patching antibot source ..."
	cp "$CFG_GITPATH_ANTIBOT"/*.{h,cpp} src/antibot/
}

function _antibot_format_binary() {
	if [ ! -f "$CFG_GITPATH_ANTIBOT"/libantibot.so ]
	then
		err "Error: invalid antibot repository $CFG_GITPATH_ANTIBOT"
		err "       found no Makefile, source patches or libantibot.so binary"
		err "       at the root of this directory '$CFG_GITPATH_ANTIBOT'"
		exit 1
	fi
	log "using precompiled libantibot.so"
	# we do nothing here in all cases the libantibot.so will
	# be expected to be in that location and then copied by cmake.sh
	# into the runtime directory
}

