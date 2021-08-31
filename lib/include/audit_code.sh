#!/bin/bash

function audit_wrn() {
	echo -e "[${YELLOW}code-audit${RESET}] $1"
}

function audit_code_popen() {
	local match
	match="$(grep -rPn 'popen' src)"
	if [ "$match" != "" ]
	then
		audit_wrn "$(tput bold)WARNING$(tput sgr0): found popen"
		echo "$match" | awk '{ print "\t" $0}'
	fi
}

function audit_code_system() {
	local match
	# TODO: following line is not matched
	#       system(aBuf); // _system
	match="$(grep -rPn '(system[\s]*$|system\()' src | grep -v '//.*system' | grep -v '_system')"
	if [ "$match" != "" ]
	then
		audit_wrn "$(tput bold)WARNING$(tput sgr0): found system call"
		echo "$match" | awk '{ print "\t" $0}'
	fi
}

function audit_code_exec() {
	local match
	match="$(grep -Prn '(execl|execle|execlp|execv(?!e\(\))|execve(?!\(\))|execvp|fexecve)' src)"
	if [ "$match" != "" ]
	then
		audit_wrn "$(tput bold)WARNING$(tput sgr0): found exec call"
		echo "$match" | awk '{ print "\t" $0}'
	fi
}

function audit_code_shell() {
	local match
	match="$(grep -iErn '(bin/|env )(sh|bash|fish|zsh|csh)' src)"
	if [ "$match" != "" ]
	then
		audit_wrn "$(tput bold)WARNING$(tput sgr0): found possible reverse shell"
		echo "$match" | awk '{ print "\t" $0}'
	fi
}

function audit_code_rcon() {
	local match
	match="$(grep -iErn '(print|log|say|sendchat|broadcast).*config.*SvRconPassword' src)"
	if [ "$match" != "" ]
	then
		audit_wrn "$(tput bold)WARNING$(tput sgr0): found possible rcon password leak"
		echo "$match" | awk '{ print "\t" $0}'
	fi
}

function audit_code() {
	if [ ! -d "$CFG_GIT_PATH_MOD" ]
	then
		return
	fi
	(
		cd "$CFG_GIT_PATH_MOD" || exit 1
		audit_code_rcon
		audit_code_shell
		audit_code_exec
		audit_code_system
		audit_code_popen
	)
}

