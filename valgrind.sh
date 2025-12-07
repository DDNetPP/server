#!/bin/bash

if [ ! -f lib/lib.sh ]
then
    echo "Error: lib/lib.sh not found!"
    echo "make sure you are in the root of the server repo"
    exit 1
fi

source lib/lib.sh

is_asan_runtime() {
	if printf '%s' "$CFG_ENV_RUNTIME" | grep -qE '(env_san.sh|fsanitize)'
	then
		return 0
	fi
	return 1
}

is_asan_build() {
	if printf '%s' "$CFG_ENV_BUILD" | grep -qE '(env_san.sh|fsanitize)'
	then
		return 0
	fi
	return 1
}

if is_asan_runtime || is_asan_build
then
	err "Error: in your server.cnf you enabled a sanitizer already"
	err "       valgrind does not work well when combined with asan and ubsan"
	err "       go to your server.cnf and check where you set env_build and env_runtime"
	err "       their current values are:"
	err ""
	err "        env_build=$CFG_ENV_BUILD"
	err "        env_runtime=$CFG_ENV_RUNTIME"
	err ""
	exit 1
fi


# WARNING: this script is not really ready to be used yet
#          valgrind cant run with asan so the entrie setup is a bit messy
#          not sure if i ever put enough love into this so its actually usable
#          but last time i lost my untracked valgrind.sh so this time i rather track
#          the messy one than to start from scratch again

srv_commit=77931f936c
SRV_BIN=./bin/solofng1_no_asan_"${srv_commit}"

cp ~/git/ddnet-insta/build-valgrind/DDNet-Server "$SRV_BIN" || exit 1


# valgrind \
# 	--tool=memcheck \
# 	--gen-suppressions=all \
# 	--suppressions=./lib/supp/memcheck.supp \
# 	--leak-check=full \
# 	--show-leak-kinds=all \

valgrind \
	--tool=massif \
	--suppressions=./lib/supp/memcheck.supp \
	"$SRV_BIN" &> logs/valgrind_"$(date '+%F_%H-%M')".txt

