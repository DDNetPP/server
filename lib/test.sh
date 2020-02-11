#!/bin/bash
# script that tests this scripts repo

testdir=lib/tmp/tests

if [ ! -d .git/ ] || [ ! -d lib/ ] || [ ! -f lib/lib.sh ]
then
    echo "Make sure you are in the root of the scripts repo"
    exit 1
fi

function clear_testdir() {
    if [ -d "$testdir" ]
    then
        rm -rf "$testdir" || exit 1
    fi
}
clear_testdir
mkdir -p "$testdir" || exit 1

read -rd '' twexec << EOF
sv_name "test server"
sv_rcon_password "rcon"
sv_port "9988"
EOF

read -rd '' servercnf << EOF
gitpath_src=~/git
gitpath_mod=~/git/ddnet7
gitpath_log=/tmp/TestLogs
server_name=testsrv-9988
binary_name=DDNet7-Server
error_logs=0
error_logs_api=curl -d "{\"err\":\"\$err\"}" -H 'Content-Type: application/json' http://localhost:80/api
EOF

function test_exec_all_servers() {
    create_server server1
    create_server "server'dgquote"
    create_server 'server"dbquote'
    create_server "server space"
    create_server "server¹²³\$p3¢!æł"
    create_server "server\\ backslash"
    cd "$testdir" || exit 1
    cd server1 || exit 1
    yes | ./lib/exec_all_servers.sh git status
    code="$?"
    if [ "$code" != "0" ]
    then
        echo "Error: exec_all_servers failed with exit code $code"
        exit 1
    fi
}

function create_server() {
    if [ "$#" != "1" ]
    then
        echo "create_server: 1 arg required"
        exit 1
    fi
    local cwd
    local servername="$1"
    local serverdir="$testdir/$servername"
    cwd="$(pwd)"
    mkdir -p "$serverdir" || exit 1
    cp ./*.sh "$serverdir"
    mkdir -p "$serverdir"/lib
    cp lib/*.sh "$serverdir"/lib
    cp -r lib/include "$serverdir"/lib
    cp -r bin/ "$serverdir"
    cp -r .git "$serverdir"
    cd "$serverdir" || exit 1
    echo "$twexec" > autoexec.cfg
    echo "$servercnf" > server.cnf
    cd "$cwd" || exit 1
}

test_exec_all_servers

clear_testdir

