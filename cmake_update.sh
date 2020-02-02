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
# TODO:
# https://github.com/koalaman/shellcheck/wiki/Sc2086#exceptions
cmake .. $cmake_flags || { err --log "build failed at $branch $(git rev-parse HEAD) (cmake)"; exit 1; }
make -j6 || { err --log "build failed at $branch $(git rev-parse HEAD) (make)"; exit 1; }
if [ ! -f "$binary_name" ]
then
    err "Binary not found is your config correct?"
    err "Expected binary name '$binary_name'"
    err "and only found those files:"
    ls
    exit 1
fi
mv "$binary_name" $cwd/bin/${srv_name}_srv_d
cp data/maps/*.map "$cwd/maps"

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

