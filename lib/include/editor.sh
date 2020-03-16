#!/bin/bash

function edit_file() {
    local file=$1
    local options
    local lines
    local selected_editor
    local aEditors
    options=()
    lines=0
    selected_editor=""
    aEditors=("vim" "vi" "nano" "emacs" "ne" "cat" "$EDITOR");
    for editor in "${aEditors[@]}"
    do
        options+=("$editor")
        lines=$((lines+1))
    done
    if [ $lines -eq 1 ]
    then
        exit 0
    fi

    if [ "$CFG_EDITOR" != "" ]
    then
        selected_editor="$CFG_EDITOR"
    elif [ "$EDITOR" != "" ]
    then
        selected_editor="$EDITOR"
    fi
    if [ "$selected_editor" == "" ]
    then
        PS3='Select a text editor: '
        select opt in "${options[@]}"
        do
            if [[ " ${options[@]} " =~ " ${opt} " ]]
            then
                selected_editor="$opt"
                return
            else
                echo "invalid option $REPLY"
            fi
        done
    fi
    eval "$selected_editor $file"
}

