#!/bin/bash

# TODO: make this a proper side runner that can be turned on and off in cnf

while true
do
    ./lib/network.sh --plain -t 3 src dst > logs/pcap/traffic.txt.tmp
    cp logs/pcap/traffic.txt.tmp logs/pcap/traffic.txt
    sleep 1
done

