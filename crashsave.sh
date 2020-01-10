#!/bin/bash

srv_name=fddrace

while true;
do
    ts=$(date +%F_%H-%M-%S)
    logfile=TeeworldsLogs/$srv_name/logs/${srv_name}_$ts
    ./${srv_name}_srv "logfile $logfile;#sid:fddrace-BlmapChill"
    ts=$(date +%F_%H-%M-%S)
    echo "+----------------------------------------+"
    echo ""
    echo ""
    figlet crash
    echo ""
    echo ""
    echo "+----------------------------------------+"
    echo "echo 'crash or shutdown $ts'" >> crashes.txt
done

