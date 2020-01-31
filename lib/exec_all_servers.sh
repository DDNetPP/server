#!/bin/bash

function require_dir() {
    local dir="$1"
    local mode="${1:-verbose}"
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

trap "exit 1" SIGUSR1
PROC="$$"

# used to kill script from subshell
fatal(){
  echo "$@" >&2
  kill -10 $PROC
}

function handle_error() {
    if [ "$IGNORE_ERR" == "yes" ] || [ "$IGNORE_ERR" == "1" ]
    then
        return
    fi
    echo "got a non zero exit code. Do you want to proceed? [y/N]"
    read -n 1 -rp "" inp
    echo ""
    if ! [[ $inp =~ ^[Yy]$ ]]
    then
        fatal "Aborting script..."
    fi
}

if [ "$#" == "0" ] || [ "$1" == "--help" ] || [ "$1" == "-h" ]
then
    echo "usage: $(basename "$0") <shell command>"
    echo "description:"
    echo "  it goes one directory up and searches server dirs"
    echo "  if a .git/ lib/ lib/lib.sh and server.cnf is found"
    echo "  it will navigate to the directory and there"
    echo "  it will execute <shell command>"
    echo "enviroment var:"
    echo "  if any of the shell commands returned a non zero exit code"
    echo "  the user will be asked to abort the script"
    echo "  to ignore this warning set the IGNORE_ERR var to 1"
    echo "example:"
    echo "  $(basename "$0") ./stop.sh;./cmake_update.sh;./start.sh"
    echo "  IGNORE_ERR=1 $(basename "$0") /usr/bin/nonzero.sh"
    exit 0
fi

check_server_dir

shell_command="$*"

echo "Found the following server directorys:"
for d in ../*/
do
    (
        cd "$d" || exit 1
        check_server_dir --silent
        echo "$d"
    )
done

echo ""
echo -e "shell_command=\\033[1m$shell_command\\033[0m"
echo "Do you want to execute shell_command in all these directorys? [y/N]"
read -n 1 -rp "" inp
echo ""
if ! [[ $inp =~ ^[Yy]$ ]]
then
    echo "Aborting script..."
    exit
fi

for d in ../*/
do
    (
        cd "$d" || exit 1
        check_server_dir --silent
        figlet "$d"
        echo -e "navigating to: \\033[1m$(pwd)\\033[0m"
        echo -e "executing: \\033[1m$shell_command\\033[0m"
        $shell_command || handle_error
    )
done

