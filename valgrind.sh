#!/bin/bash

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

