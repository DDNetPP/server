#!/bin/bash

function require_dir() {
    local dir="$1"
    local mode="${2:-verbose}"
    if [ ! -d "$dir" ]
    then
        if [ "$mode" == "verbose" ]
        then
            echo "Error: directory not found '$dir'"
            echo "  make sure you are in a server repo"
        fi
        exit 1
    fi
}

function require_file() {
    local file="$1"
    local mode="${1:-verbose}"
    if [ ! -f "$file" ]
    then
        if [ "$mode" == "verbose" ]
        then
            echo "Error: file not found '$dir'"
            echo "  make sure you are in a server repo"
        fi
        exit 1
    fi
}

function check_server_dir() {
    local mode="${1:-verbose}"
    require_dir .git/ "$mode"
    require_dir lib/ "$mode"
    require_file lib/lib.sh "$mode"
    require_file server.cnf "$mode"
}

