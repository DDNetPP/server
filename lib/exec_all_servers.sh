#!/bin/bash

if [ ! -f lib/lib.sh ]
then
    echo "Error: lib/lib.sh not found!"
    echo "make sure you are in the root of the server repo"
    exit 1
fi

source lib/lib.sh

tmp_file=/tmp/XXX_exec_all_srv.sh
is_file=0

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
    echo "parameters:"
    echo "  --help      shows this help"
    echo "  --file      edit command tmp in file"
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
    echo "  $(basename "$0") ./stop.sh;./update.sh;./start.sh"
    echo "  IGNORE_ERR=1 $(basename "$0") /usr/bin/nonzero.sh"
    exit 0
elif [ "$1" == "--script" ] || [ "$1" == "--file" ]
then
    is_file=1
    if [ ! -f "$tmp_file" ]
    then
        echo "#!/bin/bash" > "$tmp_file"
    fi
    edit_file "$tmp_file"
    chmod +x "$tmp_file"
fi

check_server_dir

shell_command="$*"

echo "Found the following server directorys:"
for d in ../*/
do
    (
        cd "$d" || exit 1
        check_server_dir > /dev/null 2>&1
        echo "$d"
    )
done

echo ""
if [ "$is_file" == "1" ]
then
    echo "script:"
    cat "$tmp_file"
    shell_command="$tmp_file"
else
    echo -e "shell_command=\\033[1m$shell_command\\033[0m"
fi
echo "Do you want to execute it in all these directorys? [y/N]"
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
        check_server_dir > /dev/null 2>&1
        figlet "$d"
        echo -e "navigating to: \\033[1m$(pwd)\\033[0m"
        echo -e "executing: \\033[1m$shell_command\\033[0m"
        eval "$shell_command" || handle_error
    )
done

