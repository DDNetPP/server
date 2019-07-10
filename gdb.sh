#!/bin/bash

if [ ! -f srv.txt ]
then
    echo "Error: srv.txt not found."
    echo "make sure you are in the server directory and created a srv.txt with the name of the server."
    exit
fi

srv=$(cat srv.txt)

gdb --args ./${srv}_srv_d "logfile /home/$USER/git/TeeworldsLogs/$srv/logs/${srv}_$(date +%F_%H-%M-%S).log"

