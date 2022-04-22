#!/bin/bash

function _log() {
	local ts_msg
	ts_msg="[$(date '+%F %H:%M:%S')]$1"
	if [ "$LOG_TS" == "1" ]
	then
		echo -ne "$ts_msg"
	else
		echo -ne "$1"
	fi
	if [ "$CFG_POST_LOGS_DIR" == "" ]
	then
		return
	fi
	if [ -d "$CFG_POST_LOGS_DIR" ]
	then
		echo -ne "$ts_msg" >> "$CFG_POST_LOGS_DIR"/server_log.txt
	fi
}

function err() {
	if [ "$#" == 2 ] && [ "$1" == "--log" ]
	then
		log_err "$2"
		_log "[${RED}error${RESET}] $2\n"
	elif [ "$#" == 2 ] && [ "$1" == "-n" ]
	then
		_log "[${RED}error${RESET}] $2"
	else
		_log "[${RED}error${RESET}] $1\n"
	fi
}

function log() {
	if [ "$#" == 2 ] && [ "$1" == "-n" ]
	then
		_log "[${YELLOW}*${RESET}] $2"
	else
		_log "[${YELLOW}*${RESET}] $1\n"
	fi
}

function wrn() {
	_log "[${YELLOW}!${RESET}] $1\n"
}

function suc() {
	if [ "$#" == 2 ] && [ "$1" == "-n" ]
	then
		_log "[${GREEN}+${RESET}] $2"
	else
		_log "[${GREEN}+${RESET}] $1\n"
	fi
}

ERR_LOGFILE=logs/error_log.txt

function is_err_log() {
	if [ "$CFG_ERROR_LOGS" == "0" ]
	then
		return 1;
	elif [ "$CFG_ERROR_LOGS" == "1" ] # 1=no duplicates 2=duplicates
	then
		if [ ! -f "$ERR_LOGFILE" ]
		then
			return 0;
		fi
		last_line="$(tail -n 1 "$ERR_LOGFILE")"
		last_line="${last_line:22}"
		if [ "$last_line" == "$1" ]
		then
			return 1
		fi
		return 0
	fi
}

function log_err() {
	local err_msg="$1"
	(
		cd "$SCRIPT_ROOT" || exit 1
		if [ ! -d .git/ ]; then
			err "log_err: .git/ not found are you in the server dir?"; return;
		elif [ ! -d lib/ ]; then
			err "log_err: lib/ not found are you in the server dir?"; return;
		elif [ ! -f server.cnf ]; then
			err "log_err: server.cnf not found are you in the server dir?"; return;
		fi
		mkdir -p logs/ || { err "log_err: failed to create logs/ directory"; return; }
		if is_err_log "$err_msg"
		then
			echo "[$(date '+%Y-%m-%d %H:%M:%S')] $err_msg" >> "$ERR_LOGFILE" || err "log_err: failed to write log"
		fi
		if [ "$CFG_ERROR_LOGS_API" != "" ]
		then
			log "pwd: $(pwd)"
			log "executing error api cmd:"
			echo "eval \"$CFG_ERROR_LOGS_API\""
			eval "$CFG_ERROR_LOGS_API"
		fi
	)
}

