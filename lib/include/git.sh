#!/bin/bash

function git_save_pull() {
    if [ "$(git status | tail -n1)" != "nothing to commit, working tree clean" ]
    then
        wrn "WARNING: git pull failed! Is your working tree clean?"
        wrn "  cd $PWD && git status"
        return
    fi
    git pull
}

