#!/bin/bash
shopt -s extglob # used for trailing slashes globbing

if [ ! -f lib/lib.sh ]
then
    echo "Error: lib/lib.sh not found!"
    echo "make sure you are in the root of the server repo"
    exit 1
fi

source lib/lib.sh &>/dev/null

maps_dir="$(pwd)/maps"

function download_web() {
    local url="$1"
    cwd="$(pwd)"
    mkdir -p "$maps_dir" || exit 1
    cd "$maps_dir" || exit 1
    url="${url%%+(/)}" # strip trailing slash
    tmp="${url#*//}"
    num_dirs="$(echo "$tmp" | tr "/" "\\n" | wc -l)"
    num_dirs="$((num_dirs - 1))"
    wget -r -np -nH --cut-dirs="$num_dirs" -R index.html "$url/"
    cd "$cwd" || exit 1
}

function download_zip() {
    local url="$1"
    cwd="$(pwd)"
    mkdir -p "$maps_dir" || exit 1
    if [ -f /tmp/XXX_maps.zip ]
    then
        rm -rf /tmp/XXX_maps.zip || exit 1
    fi
    wget -O /tmp/XXX_maps.zip "$url"
    unzip /tmp/XXX_maps.zip -d /tmp/YYY_maps
    found=0
    cd /tmp/YYY_maps/ || { err "failed to cd into '$dir'"; exit 1; }
    count="$(find . -name -maxdepth 1 '*.map' 2>/dev/null | wc -l)"
    if [ "$count" != 0 ]
    then
        log "found $count maps. copying ..."
        cp /tmp/YYY_maps/*.map "$maps_dir"
        found=1
    fi
    # check one subdir
    dir="$(find . -type d -print | tail -n1)"
    log "navigating to '$dir'"
    if [[ "$dir" != "" ]]
    then
        cd "$dir" || { err "failed to cd into '$dir'"; exit 1; }
        count="$(find . -name '*.map' 2>/dev/null | wc -l)"
        if [ "$count" != 0 ]
        then
            log "found $count maps. copying ..."
            cp /tmp/YYY_maps/"$dir"/*.map "$maps_dir"
            found=1
        fi
    fi
    if [ "$found" == "0" ]
    then
        err "did not find any maps in the zip file"
        err "url: $url"
        exit 1
    fi
    if [ -f /tmp/XXX_maps.zip ]
    then
        rm -rf /tmp/XXX_maps.zip || exit 1
    fi
    if [ -d /tmp/YYY_maps/ ]
    then
        rm -rf /tmp/YYY_maps/ || exit 1
    fi
    cd "$cwd" || exit 1
}

function download_git() {
    local url="$1"
    cwd="$(pwd)"
    mkdir -p "$maps_dir" || exit 1
    if [ -d /tmp/YYY_maps/ ]
    then
        rm -rf /tmp/YYY_maps/ || exit 1
    fi
    git clone "$url" /tmp/YYY_maps || exit 1
    cp -r /tmp/YYY_maps/* "$maps_dir"
    if [ -d /tmp/YYY_maps/ ]
    then
        rm -rf /tmp/YYY_maps/ || exit 1
    fi
    cd "$cwd" || exit 1
}

function menu() {
    check_server_dir
    if [[ -d "$maps_dir" ]] && [[ "$(ls "$maps_dir")" != "" ]]
    then
        num_maps="$(find "$maps_dir" | wc -l)"
        wrn "You already have $num_maps maps in:"
        wrn "$maps_dir"
        echo "do you want to overwrite/add to current map pool? [y/N]"
        read -n 1 -rp "" inp
        echo ""
        if ! [[ $inp =~ ^[Yy]$ ]]
        then
            echo "Aborting script..."
            exit
        fi
    fi
    # download_web http://heinrich5991.de/teeworlds/maps/maps/
    # download_zip https://maps.ddnet.tw/compilations/maps7.zip
    # download_git https://github.com/ZillyFng/solofng-maps
}

menu

