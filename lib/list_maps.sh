#!/bin/bash
# ChillerDraon's map status script

if (( $# != 1 ))
then
    echo "Usage: $0 <SQLPassword>"
    exit
fi

echo "SELECT * FROM record_maps;" | mysql -u bbnet -p"$1" bbnet

