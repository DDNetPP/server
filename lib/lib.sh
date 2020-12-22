#!/bin/bash

psaux=$(ps aux)
gitpath=/home/$USER/git

source lib/include/logger.sh
source lib/include/editor.sh
source lib/include/tw_config.sh
source lib/include/port.sh
source lib/include/dir.sh
source lib/include/sid.sh
source lib/include/deps.sh
source lib/include/settings.sh
source lib/include/git.sh
source lib/include/logs.sh

function is_cmd() {
    [ -x "$(command -v "$1")" ] && return 0
}

function get_commit()
{
    if cd "$gitpath_mod"
    then
        git rev-parse HEAD
    else
        echo "invalid"
    fi
}

function get_cores() {
    local cores
    if is_cmd nproc
    then
        cores="$(($(nproc) - 2))"
    elif is_cmd sysctl
    then
        cores="$(($(sysctl -n hw.ncpu) - 2))"
    fi
    if [ "$cores" -lt "1" ]
    then
        cores=1
    fi
    echo "$cores"
}

function save_copy() {
    if [[ ! -f "$1" ]]
    then
        return
    elif [[ "$1" == "$2" ]]
    then
        wrn "tried to copy '$1' -> '$2'"
        return
    elif [[ ! -d "$2" ]]
    then
        err "Error: save copy failed"
        err "       destination '$2' is not a directory"
        return
    fi
    cp "$1" "$2"
}

function post_logs() {
    if [ "$CFG_POST_LOGS_DIR" == "" ]
    then
        return
    fi
    log "copying logs to $CFG_POST_LOGS_DIR"
    p=logs/crashes
    save_copy "$p/status.txt" "$CFG_POST_LOGS_DIR"
    save_copy "$p/raw_build.txt" "$CFG_POST_LOGS_DIR"
    save_copy "$p/log_gdb.txt" "$CFG_POST_LOGS_DIR"
    save_copy "$p/full_gdb.txt" "$CFG_POST_LOGS_DIR"
    save_copy crashes.txt "$CFG_POST_LOGS_DIR"
}

function check_warnings() {
    local port
    local num_cores
    check_server_dir
    twcfg.check_cfg
    mkdir -p lib/tmp
    mkdir -p lib/var
    if [ -f failed_sql.sql ]
    then
        wrn "WARNING: file found 'failed_sql.sql'"
        wrn "         add these records manually to the database"
    fi
    if [ -d core_dumps ]
    then
        num_cores="$(find core_dumps/ | wc -l)"
        num_cores="$((num_cores - 1))"
        if [ "$num_cores" != "" ] && [ "$num_cores" -gt "0" ]
        then
            wrn "WARNING: $num_cores core dumps found!"
            wrn "         ckeck core_dumps/ directory"
        fi
    fi
    if is_cfg CFG_GDB_DUMP_CORE
    then
        if [ "$(cat /proc/sys/kernel/core_pattern)" != "core" ]
        then
            wrn "WARNING: unsupported coredump pattern!"
            wrn "         cat /proc/sys/kernel/core_pattern"
            wrn "         expected 'core'"
            wrn "         got '$(cat /proc/sys/kernel/core_pattern)'"
            wrn ""
            wrn "         $(tput bold)sysctl -w kernel.core_pattern=core$(tput sgr0)"
            wrn ""
        fi
    fi
    twcfg.include_exec "autoexec.cfg" > lib/tmp/compiled.cfg
    port="$(wc -l < <(grep '^sv_port ' lib/tmp/compiled.cfg))"
    if [ "$port" != "" ] && [ "$port" -gt "1" ]
    then
        wrn "WARNING: found sv_port $port times in your config"
        wrn "         avoid duplicates in config to avoid confusion."
    fi
    if [ -d ./cfg ]
    then
        if [ -d ./cfg/.git ] && [ -f ./cfg/passwords.cfg ]
        then
            (
                cd cfg || exit 1
                if ! git check-ignore -q passwords.cfg
                then
                    wrn "WARNING: file cfg/passwords.cfg found but not in cfg/.gitignore"
                fi
            )
        fi
    fi
}

function install_apt() {
    if [ "$#" != "1" ]
    then
        err "Error: install_dep invalid amount of arguments given"
        err "       expected 1 got $#"
        exit 1
    fi
    local dep="$1"
    if [ -x "$(command -v "$dep")" ]
    then
        return
    fi
    if [ ! -x "$(command -v apt)" ]
    then
        err "Error: package manager apt not found"
        err "       you have to install '$dep' manually"
        exit 1
    fi

    if [ "$UID" == "0" ]
    then
        apt install "$dep" || exit 1
    else
        if [ -x "$(command -v sudo)" ]
        then
            sudo apt install "$dep" || exit 1
        else
            err "Install sudo or switch to root user"
            exit 1
        fi
    fi
    if [ -x "$(command -v "$dep")" ]
    then
        log "Successfully installed dependency '$dep'"
    else
        err "Failed to install dependency '$dep'"
        err "please install it manually"
        exit 1
    fi
}

function install_dep() {
    install_apt "$1"
}

function show_procs() {
    local proc
    local num_procs
    local proc_str
    proc_str=${1:-$CFG_SRV_NAME}
    num_procs="$(pgrep -f "$proc_str" | wc -l)"
    if [ "$num_procs" -gt "0" ]
    then
        wrn "process with the same name is running already!"
        echo ""
        log "+--------] running processes ($num_procs) [---------+"
        for proc in $(pgrep -f "$proc_str")
        do
            ps o cmd -p "$proc" | tail -n1
        done
        log "+--------------------------------------+"
        return 0
    fi
    return 1
}

function restart_side_runner() {
    if [ ! -f "./lib/var/side_runner.sh" ]
    then
        wrn "side runner not found"
        return
    fi
    trap "stop_side_runner;exit" EXIT
    log "restarting side_runner.sh"
    pkill -f "side_runner.sh $server_id"
    ./lib/var/side_runner.sh "$server_id" > logs/side_runner.log 2>&1 &
}

function stop_side_runner() {
    if pgrep -f "side_runner.sh $server_id"
    then
        log "stopping side_runner.sh"
        pkill -f "side_runner.sh $server_id"
    fi
}

function check_running() {
    if [ "$CFG_SRV_NAME" == "" ]
    then
        err "server name is empty"
        exit 1
    fi
    if show_procs
    then
        log "do you want to start anyways? [y/N]"
        read -r -n 1 yn
        echo ""
        if ! [[ "$yn" =~ [yY] ]]
        then
            log "stopping..."
            exit
        fi
        log "ignoring duplicated process..."
    fi
    check_port
}

function check_directory() {
    local dir="$1"
    if [ ! -d "$dir" ]
    then
        err "directory not found '$dir'"
        echo ""
        log "do you want to create one? [y/N]"
        read -r -n 1 yn
        echo ""
        if [[ "$yn" =~ [yY] ]]
        then
            log "creating '$dir' directory..."
            mkdir -p "$dir"
        else
            err "no '$dir' folder found. stopping..."
            exit 1
        fi
    fi
}

function check_gitpath() {
    if [ "$gitpath_mod" == "" ]
    then
        err "gitpath mod is empty"
        exit 1
    elif [ "$CFG_LOGS_PATH" == "" ]
    then
        err "gitpath log is empty"
        exit 1
    fi
    check_directory "$gitpath_mod"
    check_directory "$CFG_LOGS_PATH"
}

function check_logdir() {
    if [ -d "$CFG_LOGS_PATH" ]
    then
        return # log path found all fine
    fi
    if [ "$CFG_SERVER_TYPE" == "tem" ]
    then
        return # tem has tem.settings logpath
    fi
    err "log path not found '$CFG_LOGS_PATH'"
    log "do you want to create this directory? [y/N]"
    yn=""
    read -r -n 1 yn
    echo ""
    if [[ "$yn" =~ [yY] ]]
    then
        mkdir "$CFG_LOGS_PATH/"
    fi
    # make sure everything
    if [ ! -d "$CFG_LOGS_PATH/" ]
    then
        err "logs path not found."
        exit 1
    fi
}

function check_deps() {
    check_gitpath
    check_logdir
    check_warnings

    logpath="$CFG_LOGS_PATH/$CFG_SRV_NAME/logs/"

    if [ "$CFG_SERVER_TYPE" == "teeworlds" ] && [ ! -f "$CFG_BIN" ]
    then
        err "server binary '$CFG_BIN' not found!"
        err "make sure the binary and your current path match"
        err "try ./github_update.sh to fetch the new binary"
        exit 1
    fi

    twcfg.check_cfg

    if [ "$CFG_SERVER_TYPE" != "tem" ]
    then
        if [ ! -d "$logpath" ]
        then
            wrn "logpath '$logpath' not found!"
            echo ""
            log "do you want to create this directory? [y/N]"
            read -r -n 1 yn
            echo ""
            if [[ ! "$yn" =~ [yY] ]]
            then
                log "stopped."
                exit
            fi
            mkdir -p "$logpath" && suc "starting server..."
        else
            if [ ! -d "$CFG_LOGS_PATH/.git" ]
            then
                wrn "WARNING: logpath is not a git repository"
            fi
        fi
    fi
}

