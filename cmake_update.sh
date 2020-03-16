#!/bin/bash

if [ ! -f lib/lib.sh ]
then
    echo "Error: lib/lib.sh not found!"
    echo "make sure you are in the root of the server repo"
    exit 1
fi

source lib/lib.sh

install_dep make
install_dep cmake
install_dep git

cwd="$(pwd)"

mkdir -p maps || { err "Error: creating dir maps/"; exit 1; }
mkdir -p logs || { err "Error: creating dir logs/"; exit 1; }
mkdir -p bin || { err "Error: creating dir bin/"; exit 1; }
cd "$gitpath_mod" || { err "Could not enter git directory"; exit 1; }
git pull || { err --log "git pull failed"; exit 1; }
mkdir -p build || { err "Error: creating dir build/"; exit 1; }
cd build || { err "Could not enter build/ directory"; exit 1; }
branch="$(git branch | sed -n '/\* /s///p')"
cmake .. "${CFG_CMAKE_FLAGS[@]}" || { err --log "build failed at $branch $(git rev-parse HEAD) (cmake)"; exit 1; }
make -j6 || { err --log "build failed at $branch $(git rev-parse HEAD) (make)"; exit 1; }
if [ ! -f "$CFG_COMPILED_BIN" ]
then
    err "Binary not found is your config correct?"
    err "Expected binary name '$CFG_COMPILED_BIN'"
    err "and only found those files:"
    ls
    exit 1
fi
mv "$CFG_COMPILED_BIN" "$cwd/bin/${CFG_SRV_NAME}_srv_d"
num_maps="$(find . -name -maxdepth 1 '*.map' 2>/dev/null | wc -l)"
if [ "$num_maps" != 0 ]
then
    log "copying $num_maps from source directory ..."
    cp data/maps/*.map "$cwd/maps"
fi

cd "$cwd" || exit 1
if [[ -d cfg/ ]] && [[ -d cfg/.git ]]
then
    log "found config directory cfg/"
    log "updating configs ..."
    cd cfg || exit 1
    git pull
fi
cd "$cwd" || exit 1
if [[ -d votes/ ]] && [[ -d votes/.git ]]
then
    log "found config directory votes/"
    log "updating configs ..."
    cd votes || exit 1
    git pull
fi
cd "$cwd" || exit 1
git_save_pull

