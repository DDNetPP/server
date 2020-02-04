#!/bin/bash
cd stats || exit 1

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

