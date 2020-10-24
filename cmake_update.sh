#!/bin/bash

if [ ! -f lib/lib.sh ]
then
    echo "Error: lib/lib.sh not found!"
    echo "make sure you are in the root of the server repo"
    exit 1
fi

source lib/lib.sh

is_force=0
if [ "$1" == "--force" ] || [ "$1" == "-f" ]
then
    is_force=1
fi

install_dep make
install_dep cmake
install_dep git

cwd="$(pwd)"

mkdir -p maps || { err "Error: creating dir maps/"; exit 1; }
mkdir -p logs || { err "Error: creating dir logs/"; exit 1; }
mkdir -p bin || { err "Error: creating dir bin/"; exit 1; }
cd "$gitpath_mod" || { err "Could not enter git directory"; exit 1; }
bin_old_commit="$(git rev-parse HEAD)"
if [ "$bin_old_commit" == "" ]
then
    err "could not determine current commit"
    bin_old_commit=invalid
fi
git pull || { git_pull=fail; }
if [[ ! -z $(git status -s) ]] || [[ "$git_pull" == "fail" ]]
then
    git submodule update
    if [ "$CFG_GIT_FORCE_PULL" == "1" ]
    then
        upstream="$(git for-each-ref --format='%(upstream:short)' "$(git symbolic-ref -q HEAD)")"
        wrn "Warning: git status not clean after pull"
        wrn "         forcing a hard reset to '$upstream'"
        git reset --hard "$upstream"
    fi
fi
if [[ ! -z $(git status -s) ]] && [[ "$is_force" == "0" ]]
then
    err --log "Error: updating the git repo failed"
    err       "       cd $gitpath_mod"
    err       "       git status"
    err       "       $(tput bold)./cmake_update.sh --force$(tput sgr0) to ignore"
    exit 1
fi
current_branch="$(git rev-parse --abbrev-ref HEAD)"
if [ "$CFG_GIT_BRANCH" != "" ]
then
    log "checking out branch specified in cfg $CFG_GIT_BRANCH ..."
    git add .. || exit 1
    git reset --hard || exit 1
    git checkout "$CFG_GIT_BRANCH"
fi
if [ "$CFG_GIT_COMMIT" != "" ]
then
    log "checking out commit specified in cfg $CFG_GIT_COMMIT ..."
    git checkout "$CFG_GIT_COMMIT"
fi
bin_commit="$(git rev-parse HEAD)"
mkdir -p build || { err "Error: creating dir build/"; exit 1; }
cd build || { err "Could not enter build/ directory"; exit 1; }
branch="$(git branch | sed -n '/\* /s///p')"
cmake .. "${CFG_CMAKE_FLAGS[@]}" || { err --log "build failed at $branch $(git rev-parse HEAD) (cmake)"; exit 1; }
make "-j$(get_cores)" || { err --log "build failed at $branch $(git rev-parse HEAD) (make)"; exit 1; }
if [ "$CFG_GIT_COMMIT" != "" ] || [ "$CFG_GIT_BRANCH" != "" ]
then
    git add .. || exit 1
    git reset --hard || exit 1
    git checkout "$current_branch"
fi
if [ ! -f "$CFG_COMPILED_BIN" ]
then
    err "Binary not found is your config correct?"
    err "Expected binary name '$CFG_COMPILED_BIN'"
    err "and only found those files:"
    ls
    exit 1
fi
if [ -f "$cwd/${CFG_BIN}" ]
then
    log "creating backup of old binary at bin/backup"
    mkdir -p "$cwd/bin/backup"
    cp "$cwd/${CFG_BIN}" "$cwd/bin/backup/$bin_old_commit"
fi
mv "$CFG_COMPILED_BIN" "$cwd/${CFG_BIN}"
num_maps="$(find ./data/maps -maxdepth 1 -name '*.map' 2>/dev/null | wc -l)"
if [ "$num_maps" != 0 ]
then
    log "copying $num_maps maps from source directory ..."
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

if [ "$CFG_TEST_RUN" == "1" ] || [ "$CFG_TEST_RUN" == "true" ]
then
    log "test if server can start ..."
    cd "$cwd" || exit 1
    if ! ./"${CFG_BIN}" "sv_port $CFG_TEST_RUN_PORT;status;shutdown"
    then
        err --log "failed to run server built with $bin_commit"
        if [ -f "$cwd/bin/backup/$bin_old_commit" ]
        then
            wrn "restoring backup binary ..."
            mv "$cwd/bin/backup/$bin_old_commit" "$cwd/${CFG_BIN}"
        fi
    fi
fi

cd "$cwd" || exit 1
git_save_pull

