#!/bin/bash

if [ ! -f lib/lib.sh ]
then
    echo "Error: lib/lib.sh not found!"
    echo "make sure you are in the root of the server repo"
    exit 1
fi

source lib/lib.sh

if [ "$1" == "--help" ] || [ "$1" == "-h" ]
then
    echo "clear script..."
    exit 0
fi

check_server_dir

function show_dir() {
    local dir
    dir="$1"
    if is_cmd tree;
    then
        tree "$dir"
    else
        echo "- $dir"
        ls "$dir"
    fi
}

function del() {
    local delete
    delete="$1"
    if [ ! -f "$delete" ] && [ ! -d "$delete" ]
    then
        err "File or directory not found '$delete'"
        return
    fi
    if [ -d "$delete" ]
    then
        log "'$delete' is a directory with $(find "$delete" | wc -l) files in it."
    fi
    log "do you want to delete '$delete'? [y/N]"
    read -r -n 1 yn
    echo ""
    if ! [[ "$yn" =~ [yY] ]]
    then
        log "aborting ..."
        return
    fi
    # mv "$delete" /tmp || { err "Error: failed to move '$delete' -> '/tmp'"; exit 1; }
    rm -rf "$delete" || { err "Error: failed to delete '$delete'"; exit 1; }
    suc "deleted '$delete'"
}

NC='\033[0m'
BLUE='\033[1;34m'

log "local files and dirs that are git ignored:"
grep -Ev '(.git|tags|server_id)' .gitignore | while IFS= read -r ignore
do
    if [ -f "$ignore" ]
    then
        echo "$ignore"
    elif [ -d "$ignore" ]
    then
        # show_dir "$ignore"
        echo -e "${BLUE}$ignore${NC}"
    fi
done

# row=0
# col=0
# function get_pos() {
#     exec < /dev/tty
#     oldstty=$(stty -g)
#     stty raw -echo min 0
#     # on my system, the following line can be replaced by the line below it
#     echo -en "\033[6n" > /dev/tty
#     # tput u7 > /dev/tty    # when TERM=xterm (and relatives)
#     IFS=';' read -r -d R -a pos
#     stty $oldstty
#     # change from one-based to zero based so they work with: tput cup $row $col
#     row=$((${pos[0]:2} - 1))    # strip off the esc-[
#     col=$((${pos[1]} - 1))
# }
# 
# dir=logs/
# cd "$dir" || exit 1
# if [ -f /tmp/"$dir".du.done ]; then rm /tmp/"$dir".du.done; fi
# du -hd 0 . | awk '{ print $1 }' > /tmp/"$dir".du; mv /tmp/"$dir".du /tmp/"$dir".du.done &
# size="..."
# printf 'logs/ ('
# get_pos
# echo "$size)"
# row="$((row-1))"
# while true;
# do
#     sleep 0.2
#     if [ -f /tmp/"$dir".du.done ]
#     then
#         size="$(cat /tmp/"$dir".du.done)"
#         or=$row
#         oc=$col
#         get_pos
#         tput cup $or $oc
#         printf '%s)' "$size"
#         tput cup $row $col
#         break
#     fi
#     sleep 0.3
# done

options="[ll]local_logs [gl]git_logs [b]binarys [lt]lib/tmp [lv]lib/var [m]maps [c]cfg"
PS3='select option to be deleted: '
select opt in $options
do
    case "$REPLY" in
        1|ll|?(\[ll\])local_logs)
            del logs/
        ;;
        2|gl|?(\[gl\])git_logs)
            del "$gitpath_log/$srv_name/logs"
        ;;
        3|b|?(\[b\])binarys)
            del "bin"
        ;;
        4|lt|?(\[lt\])lib/tmp)
            del lib/tmp
        ;;
        5|lv|?(\[lv\])lib/var)
            if echo $psaux | grep $server_id | grep -qv grep;
            then
                err "can not delete lib/var while server is running"
                err "it holds the uuid which is needed for stopping the server"
                err "make sure to kill this process first:"
                show_procs
            else
                del lib/var
            fi
        ;;
        *)
            echo "Invalid option '$REPLY'"
        ;;
    esac
done

