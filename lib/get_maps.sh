#!/bin/bash
shopt -s extglob # used for trailing slashes globbing

if [ ! -f lib/lib.sh ]
then
    echo "Error: lib/lib.sh not found!"
    echo "make sure you are in the root of the server repo"
    exit 1
fi

source lib/lib.sh

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
    local tmp_maps_archive
    local tmp_maps_dir
    tmp_maps_archive="/tmp/ddpp_$USER/maps.archive"
    tmp_maps_dir="/tmp/ddpp_$USER/maps"
    mkdir -p "/tmp/ddpp_$USER" || exit 1
    mkdir -p "$maps_dir" || exit 1
    if [ -f "$tmp_maps_archive" ]
    then
        rm -rf "$tmp_maps_archive" || exit 1
    fi
    wget -O "$tmp_maps_archive" "$url"
    unzip "$tmp_maps_archive" -d /tmp/YYY_maps
    found=0
    cd "$tmp_maps_dir" || { err "failed to cd into '$dir'"; exit 1; }
    count="$(find . -name -maxdepth 1 '*.map' 2>/dev/null | wc -l)"
    if [ "$count" != 0 ]
    then
        log "found $count maps. copying ..."
        cp "$tmp_maps_dir"*.map "$maps_dir"
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
            cp "$tmp_maps_dir""$dir"/*.map "$maps_dir"
            found=1
        fi
    fi
    if [ "$found" == "0" ]
    then
        err "did not find any maps in the zip file"
        err "url: $url"
        exit 1
    fi
    if [ -f "$tmp_maps_archive" ]
    then
        rm -rf "$tmp_maps_archive" || exit 1
    fi
    if [ -d "$tmp_maps_dir" ]
    then
        rm -rf "$tmp_maps_dir" || exit 1
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
    PS3='Please enter your choice: '
    options=(
        "vanilla"
        "heinrich5991 [BIG]"
        "ddnet [BIG]"
        "ddnet7 [BIG]"
        "KoG [BIG]"
        "ddnet++"
        "chiller"
        "zillyfng"
        "zillyfly"
        "Quit"
    )
    select opt in "${options[@]}"
    do
        case $opt in
            "vanilla")
                download_git https://github.com/teeworlds/teeworlds-maps
                break
                ;;
            "heinrich5991 [BIG]")
                download_web http://heinrich5991.de/teeworlds/maps/maps/
                break
                ;;
            "ddnet [BIG]")
                download_git https://github.com/ddnet/ddnet-maps
                break
                ;;
            "ddnet7 [BIG]")
                download_zip https://maps.ddnet.tw/compilations/maps7.zip
                break
                ;;
            "KoG [BIG]")
                download_zip https://qshar.com/maps.tar.gz
                break
                ;;
            "ddnet++")
                download_git https://github.com/DDNetPP/maps
                break
                ;;
            "chiller")
                download_git https://github.com/ChillerTW/GitMaps
                break
                ;;
            "zillyfng")
                download_git https://github.com/ZillyFng/solofng-maps
                break
                ;;
            "zillyfly")
                download_git https://github.com/ZillyFly/fly-maps
                break
                ;;
            "Quit")
                break
                ;;
            *) echo "invalid option $REPLY";;
        esac
    done
}

menu

