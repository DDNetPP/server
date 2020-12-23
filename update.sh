#!/bin/bash

if [ ! -f lib/lib.sh ]
then
    echo "Error: lib/lib.sh not found!"
    echo "make sure you are in the root of the server repo"
    exit
fi

source lib/lib.sh

source lib/include/update/cmake.sh

if [ "$1" == "--help" ] || [ "$1" == "-h" ]
then
    echo "usage: ./update.sh [OPTIONS..]"
    echo "otpions:"
    echo "  -f|--force      force build dirty git tree"
    exit 0
fi

cmake_update "$1"

