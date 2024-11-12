#!/bin/bash

function callback_editor() {
    local file="$1"
    local _editor="$2"
    bash -c "set -euo pipefail;$_editor $file" || { err "failed to open editor"; }
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
        bash -c "set -euo pipefail;$selected_editor $file" || { err "failed to open editor"; }
        return
    fi
    fzf_select \
        "Select a text editor: " "callback_editor $file" \
        vim vi nano emacs ne cat
}

