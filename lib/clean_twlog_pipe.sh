#!/bin/bash

if [ "$1" == "--help" ] || [ "$1" == "-h" ]
then
    echo "usage: cat log.txt | $(basename "$0")"
    echo "parameters:"
    echo "--help            shows this help"
    echo "--twvers=6        expects teeworlds 0.6 logfiles"
    echo "-tw=6             same as --twvers=6"
    echo "--pickups=0       filter pickup messages"
    echo "-p=0              same as --pickups=0"
    echo "examples:"
    echo "cat teeworlds.log | $(basename "$0") --twvers=6 --pickups=0"
    exit 0
fi

TW_VERSION=7
PICKUPS=1
function arg_parse() {
    local arg="$1"
    if [ "$arg" == "-tw=6" ] || [ "$arg" == "--twvers=6" ]
    then
        TW_VERSION=6
    elif [ "$arg" == "-p=0" ] || [ "$arg" == "--pickups=0" ]
    then
        PICKUPS=0
    fi
}

for arg in "$@"
do
    arg_parse "$arg"
done

TS_LEN=19
if [ "$TW_VERSION" == "6" ]
then
    TS_LEN=8
fi

if [ "$PICKUPS" == "0" ]
then
    # tw 0.6
    # [game]: pickup player='0:nameless tee' item=1/0
    # tw 0.7
    # [game]: pickup player='8:nameless tee' item=1
    egrep -v "^\[.{$TS_LEN}\]\[register\]" |
        egrep -v "^\[.{$TS_LEN}\]\[engine/mastersrv\]" |
        egrep -v "^\[.{$TS_LEN}\]\[game\]: pickup player='.*' item=[0-9](/[0-9])?$"
else
    egrep -v "^\[.{$TS_LEN}\]\[register\]" |
        egrep -v "^\[.{$TS_LEN}\]\[engine/mastersrv\]"
fi

