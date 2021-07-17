#!/bin/bash

twcfg_line=0
twcfg_last_line="firstline"

function tw_configs() {
	local flag
	local line
	for flag in "$@"
	do
		grep -r "MACRO_CONFIG_.*CFGFLAG_$flag" \
			src/ \
			--include={variables.h,config_variables.h} |
			LC_ALL=C sort | while IFS= read -r line
		do
			line="$(echo "$line" | cut -d'(' -f2 | cut -d',' -f2)"
			echo "${line:1}"
		done
	done
}

function tw_commands() {
	local flag="$1"
	local line
	grep -roh "Register(\".*CFGFLAG_$flag" src/ | LC_ALL=C sort | while IFS= read -r line
	do
		line="$(echo "$line" | cut -d'(' -f2 | cut -d'"' -f2)"
		echo "$line"
	done
}

function generate_tw_syntax() {
	(
		cd "$CFG_GIT_PATH_MOD" || exit 1
		tw_configs CLIENT SERVER ECON
		tw_commands CLIENT
		tw_commands SERVER
	) > lib/tmp/mod_syntax.cfg
}

function add_cfg_template() {
	local cfg_type
	cfg_type=$1
	log "editing $cfg_type template cfg..."
	sed "s/SERVER_NAME/$CFG_SRV_NAME/g" lib/autoexec_"${cfg_type}".txt > autoexec.cfg
	edit_file autoexec.cfg
}

function select_cfg_template() {
	PS3='Please enter your choice: '
	options=(
		"ddnet++"
		"ddnet"
		"cfg (directory)"
		"Abort"
	)
	select opt in "${options[@]}"
	do
		case $opt in
			"ddnet++")
				add_cfg_template ddnet++
				break
				;;
			"ddnet")
				add_cfg_template ddnet
				break
				;;
			"cfg (directory)")
				if [ ! -d cfg ]
				then
					log "clone config repository to ./cfg"
					log "provide git remote to repo or abort and 'mkdir cfg'"
					read -rp 'git remote url:' git_remote
					git clone "$git_remote" cfg
					if [ ! -f ./cfg/passwords.cfg ] && grep -rq '^exec cfg/passwords.cfg' cfg
					then
						{
							echo "# passwords"
							echo ""
							echo "sv_rcon_password rcon"
							echo "sv_rcon_mod_password mod"
							echo "ec_password econ"
						} > ./cfg/passwords.cfg
						edit_file ./cfg/passwords.cfg
					fi
				fi
				add_cfg_template cfg
				break
				;;
			"Abort")
				exit
				;;
			*) echo "invalid option $REPLY";;
		esac
	done
}

function twcfg.check_cfg_full() {
	twcfg.check_cfg
	twcfg.check_syntax
}

function twcfg.check_cfg() {
	if [ ! -f autoexec.cfg ]
	then
		wrn "autoexec.cfg not found!"
		echo ""
		log "do you want to create one from template? [y/N]"
		yn=""
		read -r -n 1 yn
		echo ""
		if [[ ! "$yn" =~ [yY] ]]
		then
			log "skipping config..."
			return
		fi
		select_cfg_template
	fi
}

function twcfg.check_syntax() {
	twcfg_line=0
	generate_tw_syntax
	twcfg.include_exec "autoexec.cfg" --check-syntax
}

function twcfg.check_syntax_line() {
	local line="$1"
	local line_num="$2"
	local config_file="$3"
	local key
	if [ ! -f lib/tmp/mod_syntax.cfg ]
	then
		return
	fi
	key="$(echo "$line" | cut -d' ' -f1 | xargs)"
	# value="$(echo "$line" | cut -d' ' -f2- | xargs)"
	# echo "key='$key' value='$value'"
	if [ "$key" == "" ] || [ "${key::1}" == "#" ]
	then
		return
	fi
	if grep -q "^$key$" lib/tmp/mod_syntax.cfg
	then
		return
	fi
	err "Error: syntax error in $(tput bold)$config_file:$line_num$(tput sgr0)"
	err ""
	err "       $line"
	err -n "       "
	for ((i=0;i<${#key};i++))
	do
		printf '^'
	done
	printf '\n'
	err "       invalid config/command not found in the mod code"
}

function twcfg.include_exec() {
	local config="$1"
	local check_syntax="$2"
	twcfg.check_cfg
	if [ ! -f "$config" ]
	then
		err "Error: parsing teeworlds config" >&2
		err "  $twcfg_line:$twcfg_last_line" >&2
		err "  file not found: $config" >&2
		exit 1
	fi
	# shellcheck disable=SC2094
	# https://github.com/koalaman/shellcheck/issues/1368
	while read -r line
	do
		twcfg_last_line="$line"
		if [[ "$line" =~ ^exec\ \"?(.*\.cfg) ]]
		then
			twcfg.include_exec "${BASH_REMATCH[1]}" "$check_syntax"
		else
			if [ "$check_syntax" != "" ]
			then
				twcfg.check_syntax_line "$line" "$twcfg_line" "$config"
			else
				echo "$line"
			fi
		fi
		twcfg_line="$((twcfg_line + 1))"
	done < "$config"
}

function get_tw_config() {
	if [ "$#" != "2" ]
	then
		err "Error: invalid number of arguments given get_tw_config(config_key, default_value)"
		err "       expected 2 given $#"
		return
	fi
	local config_key="$1"
	local default_value="$2"
	local found_key
	if [ ! -d lib/ ]
	then
		wrn "could not get tw config lib/ directory not found."
		return
	elif [ ! -f autoexec.cfg ]
	then
		# wrn "could not detect port due to missing autoexec.cfg"
		return
	fi
	mkdir -p lib/tmp
	twcfg_line=0
	twcfg.include_exec "autoexec.cfg" > lib/tmp/compiled.cfg
	found_key="$(grep "^$config_key " lib/tmp/compiled.cfg | tail -n1 | cut -d' ' -f2- | xargs)"
	if [ "$found_key" == "" ]
	then
		echo "$default_value"
	else
		echo "$found_key"
	fi
}

