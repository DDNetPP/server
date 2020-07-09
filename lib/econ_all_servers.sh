#!/bin/bash

if [ "$1" == "--help" ] || [ "$1" == "-h" ] || [ "$#" != "1" ]
then
    echo "usage: ./lib/econ_all_servers.sh <econ command>"
    echo ""
    echo "examples:"
    echo '  ./lib/econ_all_servers.sh "shutdown"'
    echo '  ./lib/econ_all_servers.sh "sv_shutdown_when_empty 1"'
    echo '  ./lib/econ_all_servers.sh "broadcast HELLO HOOMANS;say HELLO HOOMANS"'
    echo '  ./lib/econ_all_servers.sh "exec script.cfg"'
    exit 0
fi

./lib/exec_all_servers.sh ./lib/econ.sh "$1"

