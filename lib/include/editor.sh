#!/bin/bash

function edit_file() {
    local file=$1
    options=()
    lines=0
    editors="vim vi nano emacs ne cat"
    aEditors=($editors);
    for editor in "${aEditors[@]}"
    do
        options+=("$editor")
        lines=$((lines+1))
    done
    if [ $lines -eq 1 ]
    then
        exit 0
    fi

    PS3='Select a text editor: '
    select opt in "${options[@]}"
    do
        if [[ " ${options[@]} " =~ " ${opt} " ]]
        then
            $opt $file
            return
        else
            echo "invalid option $REPLY"
        fi
    done
}

