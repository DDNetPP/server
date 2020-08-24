#!/bin/bash
if [ "$1" == "--help" ] || [ "$1" == "-h" ]
then
    echo "usage: $(basename "$0") [OPTIONS] [PATH] [OPTIONS]"
    echo "description: creates git commits every 65h"
    echo "path:"
    echo "  git directory (default=stats)"
    echo "options:"
    echo "  --no-push   do not git push"
    echo "  --no-pull   do not git pull"
    exit 0
fi

is_push=1
is_pull=1

for arg in "$@"
do
    # OPTION
    if [ "${arg:0:1}" == "-" ]
    then
        if [ "$arg" == "--no-push" ]
        then
            is_push=0
        elif [ "$arg" == "--no-pull" ]
        then
            is_pull=0
        else
            echo "no such option '$arg' try --help for a full list"
            exit 1
        fi
        continue
    fi

    # PATH
    if [ "$arg" == "" ]
    then
        cd stats || exit 1
    else
        cd "$arg" || exit 1
    fi
done

function sleep_hours() {
    hours=$1
    for ((i=0;i<hours;i++))
    do
        sleep 1h
        printf .
    done
    echo ""
}

while true
do
    date=$(date '+%Y-%m-%d')
    echo "commiting at $(date) ..."
    if [ "$is_pull" == "1" ]; then git pull; fi
    if [ "$is_push" == "1" ]; then git push; fi
    git add .
    git commit -m "Update $date"
    if [ "$is_push" == "1" ]; then git push; fi
    echo "sleeping 65 hours"
    sleep_hours 65
done

