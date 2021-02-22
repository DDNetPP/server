#!/bin/bash

function echo_arr() {
    local i
    for i in "$@"
    do
        echo "$i"
    done
}

function fzf_select() {
    # usage: fzf_select prompt callback options.."
    # example: fzf_select "pick a foo" my_callback foo bar baz
    local prompt="$1"
    local callback="$2"
    local choice
    local o
    shift
    shift
    if [ -x "$(command -v fzf)" ]
    then
        choice="$(echo_arr "$@" | fzf)"
        eval "$callback $choice"
    else
        PS3="$prompt"
        select choice in "$@"
        do
            for o in "$@"
            do
                if [[ "$o" == "$choice" ]]
                then
                    eval "$callback $choice"
                    return
                fi
            done
            echo "invalid option $REPLY"
        done
    fi
}

