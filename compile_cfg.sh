#!/bin/bash

function include_exec() {
    local config="$1"
    while read -r line
    do
        if [[ "$line" =~ exec\ (.*\.cfg) ]]
        then
            include_exec "${BASH_REMATCH[1]}"
        else
            echo "$line"
        fi
    done < "$config"
}

include_exec "autoexec.cfg"

