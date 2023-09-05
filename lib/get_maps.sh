#!/bin/bash
shopt -s extglob # used for trailing slashes globbing

if [ ! -f lib/lib.sh ]
then
    echo "Error: lib/lib.sh not found!"
    echo "make sure you are in the root of the server repo"
    exit 1
fi

source lib/lib.sh

maps_dir="${SCRIPT_ROOT}/maps"

function download_web() {
    local url="$1"
    mkdir -p "$maps_dir" || exit 1
    cd "$maps_dir" || exit 1
    url="${url%%+(/)}" # strip trailing slash
    tmp="${url#*//}"
    num_dirs="$(echo "$tmp" | tr "/" "\\n" | wc -l)"
    num_dirs="$((num_dirs - 1))"
    wget -r -np -nH --cut-dirs="$num_dirs" -R index.html "$url/"
    cd "$SCRIPT_ROOT" || exit 1
}

function download_archive() {
    local archive_type="$1"
    local url="$2"
    local archive_name
    local tmp_maps_archive
    local tmp_maps_dir
    archive_name="${url##*/}"
    archive_name="$(basename "$archive_name" ".$archive_type")"
    tmp_maps_root="/tmp/ddpp_$USER"
    tmp_maps_archive="$tmp_maps_root/maps.archive"
    tmp_maps_dir="$tmp_maps_root/maps"
    mkdir -p "$tmp_maps_root" || exit 1
    mkdir -p "$maps_dir" || exit 1
    if [ -f "$tmp_maps_archive" ]
    then
        rm -rf "$tmp_maps_archive" || exit 1
    fi
    if [ -d "$tmp_maps_dir" ]
    then
        rm -rf "$tmp_maps_dir" || exit 1
    fi
    wget -O "$tmp_maps_archive" "$url"
    if [ "$archive_type" == "zip" ]
    then
        unzip "$tmp_maps_archive" -d "$tmp_maps_dir"
    elif [ "$archive_type" == "tar.gz" ]
    then
        tar -xvzf "$tmp_maps_archive" -C "$tmp_maps_root"
        mv "$tmp_maps_root/$archive_name" "$tmp_maps_dir" || exit 1
    elif [ "$archive_type" == "tar.xz" ]
    then
        tar -xf "$tmp_maps_archive" -C "$tmp_maps_root"
        mv "$tmp_maps_root/$archive_name" "$tmp_maps_dir" || exit 1
    else
        err "unsupported archive_type '$archive_type'"
        exit 1
    fi
    found=0
    cd "$tmp_maps_dir" || { err "failed to cd into '$dir'"; exit 1; }
    count="$(find . -name -maxdepth 1 '*.map' 2>/dev/null | wc -l)"
    if [ "$count" != 0 ]
    then
        log "found $count maps. copying ..."
        cp "$tmp_maps_dir"*.map "$maps_dir"
        found=1
    fi
    # check one first subdir or data/maps to look for more maps
    dir="$(find . -type d -print | tail -n1)"
    if [ -d data/maps ]
    then
        dir=data/maps
    fi
    if [[ "$dir" != "" ]]
    then
        log "navigating to '$dir'"
        cd "$dir" || { err "failed to cd into '$dir'"; exit 1; }
        count="$(find . -name '*.map' 2>/dev/null | wc -l)"
        if [ "$count" != 0 ]
        then
            log "found $count maps. copying ..."
            cp "$tmp_maps_dir/$dir"/*.map "$maps_dir"
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
    cd "$SCRIPT_ROOT" || exit 1
}

function download_git() {
    local url="$1"
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
    cd "$SCRIPT_ROOT" || exit 1
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
        "vanilla git"
        "vanilla 0.7.1 release"
        "vanilla 0.6.5 release"
        "heinrich5991 [BIG]"
        "ddnet [BIG]"
        "ddnet7 [BIG]"
        "KoG [BIG]"
        "ddnet++"
        "chiller"
        "zillyfng"
        "zillyfly"
	"zillyinsta"
        "Quit"
    )
    select opt in "${options[@]}"
    do
        case $opt in
            "vanilla git")
                download_git https://github.com/teeworlds/teeworlds-maps
                break
                ;;
            "vanilla 0.7.1 release")
                download_archive tar.gz https://github.com/teeworlds/teeworlds/releases/download/0.7.1/teeworlds-0.7.1-linux_x86_64.tar.gz
                break
                ;;
            "vanilla 0.6.5 release")
                download_archive tar.xz https://downloads.teeworlds.com/teeworlds-0.6.5-linux_x86_64.tar.xz
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
                download_archive zip https://maps.ddnet.tw/compilations/maps7.zip
                break
                ;;
            "KoG [BIG]")
                download_archive tar.gz https://qshar.com/maps.tar.gz
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
            "zillyinsta")
                download_git https://github.com/ZillyInsta/maps
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

