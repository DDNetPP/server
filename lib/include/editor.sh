#!/bin/bash

function callback_editor() {
    local file="$1"
    local editor="$2"
    eval "$editor $file"
}

function edit_file() {
    local file=$1
    local selected_editor=""
    if [ "$CFG_EDITOR" != "" ]
    then
        selected_editor="$CFG_EDITOR"
    elif [ "$EDITOR" != "" ]
    then
        selected_editor="$EDITOR"
    fi
    if [ "$selected_editor" != "" ]
    then
        eval "$selected_editor $file"
        return
    fi
    fzf_select \
        "Select a text editor: " "callback_editor $file" \
        vim vi nano emacs ne cat
}

