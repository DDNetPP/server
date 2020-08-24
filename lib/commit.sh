#!/bin/bash
if [ "$1" == "--help" ] || [ "$1" == "-h" ]
then
    echo "usage: $(basename "$0") [PATH]"
    echo "description: creates git commits every 65h"
    echo "options:"
    echo "  PATH    git directory (default=stats)"
    exit 0
fi
if [ "$1" == "" ]
then
    cd stats || exit 1
else
    cd "$1" || exit 1
fi

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
    git pull
    git push
    git add .
    git commit -m "Update $date"
    git push
    echo "sleeping 65 hours"
    sleep_hours 65
done

