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

_audit_code_system_whitelisted_systems=(
	'#ifndef EGL_NV_stream_cross_system'
	'#ifdef EGL_NV_stream_cross_system'
	'/* ----------------------- EGL_NV_stream_cross_system ---------------------- */'
	'** implementation is available on the host platform, the mutex subsystem'
	'** CAPI3REF: Memory Allocation Subsystem'
	'** matches the request for a function with nArg arguments in a system'
	'** synced to disk. The journal file still exists in the file-system'
	'** Convert a filename from whatever the underlying operating system'
	'** assert() macro is enabled, each call into the Win32 native heap subsystem'

)
_audit_code_system_whitelisted_buffers=(
	'	str_format(aBuf, sizeof(aBuf), "xdg-open %s >/dev/null 2>&1 &", link);'
	'	str_format(aBuf, sizeof(aBuf), "open %s &", link);'
	"	str_format(aBuf, sizeof(aBuf), \"xdg-open '%s' >/dev/null 2>&1 &\", link);"
	'	str_format(aBuf, sizeof aBuf, "chmod +x %s", aPath);'
	'	m_pStorage->GetBinaryPath(PLAT_SERVER_EXEC, aPath, sizeof aPath);'
	'	char aBuf[512];'
	'	m_pStorage->GetBinaryPath(PLAT_CLIENT_EXEC, aPath, sizeof aPath);'
)

function _get_grep_context() {
	# SYNOPSIS:
	#  _get_grep_context <line>
	# DESCRIPTION:
	#  given a matches line from grep -B output
	#  it will return - or : depeding if its the
	#  context or actual match
	[[ "$1" =~ [^a-zA-Z0-9/.] ]] && printf '%s' "${BASH_REMATCH[0]}"
}

function _chop_grep_line() {
	# SYNOPSIS:
	#   _chop_grep_line <line>
	# DESCRIPTION:
	#   strips of file and line match from grep -nr
	#   also supporting -B context lines
	local line="$1"
	local context
	local ret=''
	context="$(_get_grep_context "$line")"
	ret="${line#*$context}"
	ret="${ret#*$context}"
	printf '%s\n' "$ret"
}

function audit_code_system() {
	local match
	local num_matches=0
	local line
	local line_type=''
	local detect=0
	local chunk
	local chunks=()
	local buf=''
	local seek_buf=''
	local num_systems=0
	match="$(grep -rPnB 3 '(system[\s]*$|system\()' src)"
	# parse grep multi line matches into bash array chunks
	while IFS= read -r line
	do
		if [ "$line" == "--" ]
		then
			chunks+=("$buf")
			buf=''
		else
			# appends 'line' to 'buf' with an actual newline character
			printf -v buf '%s\n%s' "$buf" "$line"
		fi
	done <<< "$match"
	match=''
	# scan chunks for actual matches
	for chunk in "${chunks[@]}"
	do
		detect=1
		while IFS=$'\n' read -r line
		do
			if [ "$line" == "" ]
			then
				continue
			fi
			line_type="$(_get_grep_context "$line")"
			line_chopped="$(_chop_grep_line "$line")"
			# grep context matches
			# search for defined buffers
			if [ "$line_type" == "-" ]
			then
				for buf in "${_audit_code_system_whitelisted_buffers[@]}"
				do
					if [ "$seek_buf" == "" ]
					then
						continue
					fi
					if ! [[ "$line_chopped" == *"$seek_buf"* ]]
					then
						continue
					fi
					if [ "$line_chopped" == "$buf" ]
					then
						detect=0
						if [[ "$line_chopped" == *"aPath"* ]]
						then
							seek_buf=aPath
						else
							seek_buf=''
						fi
						break
					else
						detect=1
					fi
				done
				if [ "$detect" == "1" ]
				then
					break
				fi
				continue
			fi
			buf="${line//system}"
			num_systems="$(( (${#line} - ${#buf}) / ${#line} ))"
			if [[ "$num_systems" -gt "1" ]]
			then
				detect=1
				break
			elif [[ "$line" =~ //.*system ]]
			then
				detect=0
			elif [[ "$line" =~ system\(([^\)]+)\) ]]
			then
				seek_buf="${BASH_REMATCH[1]}"
			else
				for buf in "${_audit_code_system_whitelisted_systems[@]}"
				do
					if [ "$line_chopped" == "$buf" ]
					then
						detect=0
						break
					fi
				done
			fi
		done < <(echo "$chunk" | tac) # reverse to get get buffer name first
		if [ "$detect" == "1" ]
		then
			printf -v match '%s\n%s' "$match" "$chunk"
			num_matches="$((num_matches + 1))"
		fi
	done
	if [ "$match" != "" ]
	then
		audit_wrn "$(tput bold)WARNING$(tput sgr0): found $num_matches system calls"
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

