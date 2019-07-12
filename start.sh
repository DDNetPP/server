#!/bin/bash

if [ ! -f srv.txt ]
then
    echo "Error: srv.txt not found."
    echo "make sure you are in the server directory and created a srv.txt with the name of the server."
    exit
fi

if [ ! -d /home/$USER/git/TeeworldsLogs ]
then
    echo "Error: log path not found /home/$USER/git/TeeworldsLogs"
    echo "make sure to create this folder"
    exit
fi

srv=$(cat srv.txt)

if [ ! -f "$srv" ]
then
    echo "Error: server binary '$srv' not found!"
    echo "make sure the binary and your current path match"
    echo "try ./github_update.sh to fetch the new binary"
    exit
fi

nohup ./${srv}_srv_d > /home/$USER/git/TeeworldsLogs/$srv/logs/${srv}_$(date +%F_%H-%M-%S).log 2>&1 &

