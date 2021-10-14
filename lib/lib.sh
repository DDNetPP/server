#!/bin/bash

SCRIPT_ROOT="$(pwd)"
export SCRIPT_ROOT

source lib/include/colors.sh
source lib/include/logger.sh
source lib/include/common.sh
source lib/include/editor.sh
source lib/include/tw_config.sh
source lib/include/port.sh
source lib/include/dir.sh
source lib/include/sid.sh
source lib/include/deps.sh
source lib/include/settings.sh
source lib/include/git.sh
source lib/include/logs.sh
source lib/include/screen.sh
source lib/include/audit_code.sh
source lib/include/traffic_logger.sh
# UNUSED for now...
# source lib/include/external/dylanaraps/pure-bash-bible.sh

function is_running_loop() {
	if pgrep -f "$SERVER_UUID:loop_script" > /dev/null
	then
		return 0
	fi
	return 1
}

function get_player_ips() {
	if [ ! "$(command -v rg)" ]
	then
		return
	fi
	local kill_id
	kill_id="$(od -xN16 /dev/urandom | awk -v OFS=- '{print $2$3,$4,$5,$6,$7$8$9; exit}')"
	# subshell to swallow all background process messages
	(
		./lib/econ-output.exp \
			"$(get_tw_config ec_bindaddr localhost)" \
			"$(get_tw_config ec_port 8303)" \
			"$(get_tw_config ec_password pass)" \
			status \
			id="$kill_id" | \
			strings > lib/tmp/status_"$USER".txt &
		sleep 3
		pkill -f "id=$kill_id"
	) &> /dev/null
	# shellcheck disable=SC2016
	rg --color never -No ': id=.* addr=<\{(.*):.*\}>' -r '$1' lib/tmp/status_"$USER".txt
}

function del_file() {
    local file="$1"
    if [ -f "$file" ]
    then
        echo "[!] deleting file '$file' ..."
        rm "$file"
    fi
}

function is_cmd() {
    [ -x "$(command -v "$1")" ] && return 0
}

function get_commit()
{
    if cd "$CFG_GIT_PATH_MOD"
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

function save_move() {
	if [[ ! -f "$1" ]]
	then
		return
	elif [[ "$1" == "$2" ]]
	then
		wrn "tried to move '$1' -> '$2'"
		return
	elif [[ ! -d "$2" ]]
	then
		err "Error: save move failed"
		err "       destination '$2' is not a directory"
		return
	fi
	mv "$1" "$2"
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

function delete_files_except_latest() {
    local dir="$1"
    local num_keep="$2"
    if [ ! -d "$dir" ]
    then
        return
    fi
    local num_files
    num_files="$(find "$dir" | wc -l)"
    num_files="$((num_files-2))"
    if [ "$num_files" -lt "$num_keep" ]
    then
        return
    fi
    # https://stackoverflow.com/a/47593062
    find "$dir" -type f -printf '%T@\t%p\n' |
        sort -t $'\t' -g |
        head -n -"$num_keep" |
        cut -d $'\t' -f 2- |
        xargs rm
}

function warn_dir_size() {
    local dir="$1"
    local delete="$2"
    local size
    local cache=./lib/tmp/size_"${dir//\//_}".txt
    if [ -f "$cache" ]
    then
        rm "$cache"
    fi
    if [ ! -d "$dir" ]
    then
        return
    fi
    if du -hd 1 "$dir" | tail -n1 | awk '{print $1}' | grep -q G
    then
        {
            wrn "WARNING: directory $(tput bold)$dir$(tput sgr0) is measured in gigabytes"
            while IFS= read -r size
            do
                wrn "         $size"
            done < <(du -hd 1 "$dir")
            local num_files
            num_files="$(find "$dir" | wc -l)"
            num_files="$((num_files-2))"
            if [ "$delete" == "1" ] && is_cfg CFG_AUTO_CLEANUP_OLD_LOCAL_DATA
            then
                if [ "$num_files" -lt "5" ]
                then
                    wrn "CLEANUP:"
                    wrn "         failed to cleanup! Latest 5 files alone are too big!"
                    return
                fi
                log "CLEANUP:"
                log "         removing all files from '$(tput bold)$dir$(tput sgr0)' except latest 5"
                delete_files_except_latest "$dir" 5
            fi
        } > "$cache"
    fi
}

function check_dir_size() {
    warn_dir_size bin/backup 1 &
    warn_dir_size cfg 0 &
    warn_dir_size cnf 0 &
    warn_dir_size core_dumps 1 &
    warn_dir_size lib 0 &
    warn_dir_size logs/ddos 1 &
    warn_dir_size logs 0 &
    warn_dir_size maps  0&
    wait
    touch ./lib/tmp/size_null.txt
    cat ./lib/tmp/size_*.txt
}

function check_duplicated_uuid() {
	local d
	local comp_uuid
	local current_dir
	current_dir="../$(basename "$(pwd)")/"
	for d in ../*/
	do
	    (
		cd "$d" || exit 1
		check_server_dir > /dev/null 2>&1
		if [ "$current_dir" == "$d" ]
		then
			# skip this instance
			exit 0
		fi
		comp_uuid="$(cat "$SID_FILE")"
		if [ "$comp_uuid" == "$SERVER_UUID" ]
		then
			wrn "Warning: same server uuid used in $(tput bold)$d$(tput sgr0)"
			wrn "         make sure two directorys have never the same uuid"
			wrn "         otherwise you might stop servers you do not want to stop"
			wrn "         fix it by shutting down the server and deleting the uuid"
			wrn ""
			wrn "           $(tput bold)./stop.sh && rm $SID_FILE$(tput sgr0)"
			wrn ""
		fi
	    )
	done
}

function check_warnings() {
    local port
    local num_cores
    check_server_dir
    twcfg.check_cfg_full
    check_dir_size
    check_duplicated_uuid
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
        if [ "$num_cores" != "" ] && [ "$num_cores" -gt "5" ]
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
    show_procs_name "$CFG_SRV_NAME"
}

function show_procs_name() {
    local proc
    local num_procs
    local proc_str
    proc_str="$1"
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

function crash_save_tem() {
	# give server 3 secs to start
	sleep 3
	while true
	do
		mkdir -p "${SCRIPT_ROOT}/logs/tem"
		local log_ext="${CFG_LOG_EXT:-.log}"
		local logfile="${SCRIPT_ROOT}/logs/tem/tem_$(date +%F_%H-%M-%S)${log_ext}"
		./start_tem.sh "$CFG_TEM_SETTINGS" "#sid:$SERVER_UUID" > "$logfile" 2>&1
		sleep 5
	done
}
export -f crash_save_tem

function restart_side_runner() {
	trap "stop_side_runner;exit" EXIT
	log "restarting side_runners .."
	pkill -f "side_runner.sh $SERVER_UUID"
	for plugin in ./lib/plugins/*/
	do
		[ -d "$plugin" ] || continue
		[ -f "$plugin"side_runner.sh ] || continue

		log "starting side runner $(basename "$plugin")/side_runner.sh .."
		"$plugin"side_runner.sh "$SERVER_UUID" > logs/side_runner_"$(basename "$plugin")".log 2>&1 &
	done
	if is_cfg CFG_TEM_SIDE_RUNNER
	then
		pkill -f "start_tem.sh.*$SERVER_UUID"
		pkill -f -- "crash_save_tem --uuid=$SERVER_UUID"
		(
			cd "$CFG_TEM_PATH" || exit 1
			nohup bash -c "crash_save_tem --uuid=$SERVER_UUID" 2>&1 &
			log "starting side runner TEM .."
		)
	fi
}

function stop_side_runner() {
	if pgrep -f "side_runner.sh $SERVER_UUID"
	then
		log "stopping side_runner.sh"
		pkill -f "side_runner.sh $SERVER_UUID"
	fi
	pkill -f "start_tem.sh.*$SERVER_UUID"
	pkill -f -- "crash_save_tem --uuid=$SERVER_UUID"
	pkill -f -- "settings=$CFG_TEM_SETTINGS"
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
            log "aborting ..."
            exit
        fi
        log "ignoring duplicated process..."
    fi
    check_port
}

function check_directory() {
	local yes="$1"
	local dir="$2"
	if [ ! -d "$dir" ]
	then
		err "directory not found '$dir'"
		echo ""
		log "do you want to create one? [y/N]"
		if [ "$yes" == "--yes" ] || [ "$yes" == "-y" ]
		then
			yn=yes
			echo "yes"
		else
			read -r -n 1 yn
		fi
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
	if [ "$CFG_GIT_PATH_MOD" == "" ]
	then
		err "gitpath mod is empty"
		exit 1
	elif [ "$CFG_LOGS_PATH" == "" ]
	then
		err "gitpath log is empty"
		exit 1
	fi
	check_directory "$1" "$CFG_GIT_PATH_MOD"
	check_directory "$1" "$CFG_LOGS_PATH"
}

function check_logdir() {
	if [ -d "$LOGS_PATH_FULL" ]
	then
		if [ ! -d "$CFG_LOGS_PATH/.git" ]
		then
			wrn "WARNING: log path is not a git repository"
		fi
		return # log path found all fine
	fi
	err "log path not found '$LOGS_PATH_FULL'"
	log "do you want to create this directory? [y/N]"
	local yn=""
	if [ "$1" == "--yes" ] || [ "$1" = "-y" ]
	then
		yn=yes
		echo "yes"
	else
		read -r -n 1 yn
	fi
	echo ""
	if [[ "$yn" =~ [yY] ]]
	then
		mkdir -p "$LOGS_PATH_FULL" && suc "created logs directory"
	else
		log "stopped."
		exit 1
	fi
}

function check_lib_teeworlds() {
	if [ -x "$(command -v tw_get_ip_by_name)" ]
	then
		return
	fi
	if [ -d "$HOME"/.lib-crash/lib-teeworlds ]
	then
		return
	fi
	log "installing lib-crash/lib-teeworlds ..."
	git clone git@github.com:lib-crash/lib-teeworlds "$HOME"/.lib-crash/lib-teeworlds
	if [ ! -f ~/.bashrc ]
	then
		return
	fi
	if ! grep -q '^export PATH.*lib-crash/lib-teeworlds/bin' ~/.bashrc
	then
		log "adding lib-crash/lib-teeworlds/bin to PATH ..."
		# shellcheck disable=SC2016
		echo 'export PATH="$PATH:$HOME/.lib-crash/lib-teeworlds/bin"' >> ~/.bashrc
	fi
}

function check_deps() {
	check_gitpath "$1"
	check_logdir "$1"
	check_lib_teeworlds

	if [ "$CFG_SERVER_TYPE" == "teeworlds" ] && [ ! -f "$CFG_BIN" ]
	then
		err "server binary '$CFG_BIN' not found!"
		err "make sure the binary and your current path match"
		err "try ./update.sh to fetch the new binary"
	exit 1
	fi

	twcfg.check_cfg
}

function update_configs() {
	cd "$SCRIPT_ROOT" || exit 1
	if [[ -d cfg/ ]] && [[ -d cfg/.git ]]
	then
		log "found config directory cfg/"
		log "updating configs ..."
		cd cfg || exit 1
		git_save_pull
	fi
	cd "$SCRIPT_ROOT" || exit 1
	if [[ -d votes/ ]] && [[ -d votes/.git ]]
	then
		log "found config directory votes/"
		log "updating votes ..."
		cd votes || exit 1
		git_save_pull
	fi
	cd "$SCRIPT_ROOT" || exit 1
	if [[ -d cnf/ ]] && [[ -d cnf/.git ]]
	then
		log "found settings directory cnf/"
		log "updating settings ..."
		cd cnf || exit 1
		git_save_pull
	fi
	for plugin in ./lib/plugins/*/
	do
		cd "$SCRIPT_ROOT" || exit 1
		[ -d "$plugin" ] || continue
		[ -d "$plugin".git ] || continue

		log "updating plugin $(tput bold)$(basename "$plugin")$(tput sgr0) ..."
		cd "$plugin" || exit 1
		git_save_pull
	done
}

function archive_gmon() {
	mkdir -p logs/{gmon,gprof}
	local dst
	local ts
	ts="$(date '+%F_%H-%M')"
	if [ -f gmon.out ]
	then
		if [ ! -x "$(command -v gprof2dot)" ] || [ ! -x "$(command -v dot)" ]
		then
			wrn "missing dependency $(tput bold)gprof2dot$(tput sgr0) and $(tput bold)dot$(tput sgr0)"
			wrn "skipping callgraph generation..."
		else
			log "generating gprof callgraph ..."
			gprof ./"$CFG_BIN" | gprof2dot | dot -Tsvg -o gprof.svg
			save_copy gprof.svg "$CFG_POST_LOGS_DIR"
		fi
		dst=logs/gmon/gmon_"$ts".out
		log "archiving $dst ..."
		mv gmon.out "$dst"
	fi
	if [ -f gprof.svg ]
	then
		dst=logs/gprof/gprof_"$ts".svg
		log "archiving $dst ..."
		mv gprof.svg "$dst"
	fi
}

