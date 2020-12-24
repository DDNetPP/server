if [ ! -f lib/lib.sh ]
then
    echo "Error: lib/lib.sh not found!"
    echo "make sure you are in the root of the server repo"
    exit 1
fi

source lib/lib.sh

figlet "lib.sh"
echo "show_logs"
echo "show_procs"
echo "get_tw_config <key> <default>"
PS1='> '
