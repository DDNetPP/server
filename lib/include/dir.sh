#!/bin/bash

function require_dir() {
    local dir="$1"
    if [ ! -d "$dir" ]
    then
        echo "Error: directory not found '$dir'"
        echo "  make sure you are in a server repo"
        exit 1
    fi
}

function require_file() {
    local file="$1"
    if [ ! -f "$file" ]
    then
        echo "Error: file not found '$file'"
        echo "  make sure you are in a server repo"
        exit 1
    fi
}

function check_server_dir() {
    require_dir .git/
    require_dir lib/
    require_file lib/lib.sh
    # do not require server.cnf or it will fail before creating server.cnf
    # require_file server.cnf "$mode"
}

