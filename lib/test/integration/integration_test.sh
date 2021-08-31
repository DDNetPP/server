#!/bin/bash
# script that tests this scripts repo

root_dir="$(pwd)"
integration_root_dir="${root_dir}/lib/test/integration"
testdir="$root_dir"/lib/tmp/tests

if [ ! -d .git/ ] || [ ! -d lib/ ] || [ ! -f lib/lib.sh ]
then
	echo "Make sure you are in the root of the scripts repo"
	exit 1
fi

function clear_testdir() {
	cd "$root_dir" || exit 1
	if [ -d "$testdir" ]
	then
		rm -rf "$testdir" || exit 1
	fi
}
clear_testdir
mkdir -p "$testdir" || exit 1

read -rd '' twexec << EOF
sv_name "test server"
sv_rcon_password "rcon"
sv_port "9988"
EOF

read -rd '' servercnf << EOF
git_root=~/git
gitpath_mod=$testdir/git/mod
gitpath_log=$testdir/git/logs
server_name=testsrv-9988
compiled_teeworlds_name=teeworlds_srv
cmake_flags=-DCMAKE_BUILD_TYPE=Debug
error_logs=0
# error_logs_api=curl -d "{\"err\":\"\$err\"}" -H 'Content-Type: application/json' http://localhost:80/api
error_logs_api=test
EOF

read -rd '' crashmod_main << EOF
#include <stdio.h>
#include <cstring>

FILE *fp;

void log(const char *str)
{
	puts(str);
	if(fp)
	{
		fprintf(fp, "%s", str);
		fprintf(fp, "%s", "\n");
	}
}

int main(int argc, char *argv[]) {
	char *delim;
	char *logfile;
	if (argc > 1)
	{
		logfile = strstr(argv[1], "logfile ");
		logfile += strlen("logfile ");
		if(logfile)
		{
			delim = strstr(logfile, ";");
			if(delim)
				delim[0] = '\0';
			printf("logfile '%s'\n", logfile);
			fp = fopen(logfile, "a");
		}
	}
	log("starting crashy server....");
	if(fp)
		fclose(fp);
	*((volatile unsigned*)0) = 0x0;
	return 0;
}
EOF

read -rd '' crashmod_cmakelist << EOF
cmake_minimum_required(VERSION 3.0)
project(crash_mod)

add_executable(teeworlds_srv main.cpp)
EOF

function fail() {
	clear_testdir
	echo "[-] Error: test failed"
	exit 1
}

function test_exec_all_servers() {
	num_servers=0
	create_server server1
	create_server "server'dgquote"
	create_server 'server"dbquote'
	create_server "server space"
	create_server "server¹²³\$p3¢!æł"
	create_server "server\\ backslash"
	cd "$testdir" || fail
	cd server1 || fail
	yes | ./lib/exec_all_servers.sh git status
	code="$?"
	if [ "$code" != "0" ]
	then
		echo "Error: 'exec_all_servers.sh git status' failed with exit code $code"
		fail
	fi
	yes | ./lib/exec_all_servers.sh touch foo.txt
	code="$?"
	if [ "$code" != "0" ]
	then
		echo "Error: 'exec_all_servers.sh touch foo.txt' failed with exit code $code"
		fail
	fi
	local foo_files
	foo_files="$(find .. -name foo.txt | wc -l)"
	if [ "$foo_files" != "$num_servers" ]
	then
		echo "Error: 'exec_all_servers.sh touch foo.txt' found $foo_files foo.txt files but expected $num_servers"
		fail
	fi
}

function test_loop_gdb() {
	create_server "loop_gdb"
	cd "$testdir" || fail
	local num_logs=0
	local _=0
	mkdir -p git/mod
	(
		cd git/mod || exit 1
		git init
		echo "$crashmod_main" > main.cpp
		echo "$crashmod_cmakelist" > CMakeLists.txt
		cp -r "$integration_root_dir/src" .
		git add .
		git commit -m "initial commit"
	) || fail
	cd loop_gdb || fail
	./update.sh
	./loop_gdb.sh --yes --test &> ./logs/test_gdb.txt &
	echo -n "[*] test loop_gdb.sh ."
	for _ in {1..15}
	do
		printf '.'
		sleep 1
	done
	pkill -f './loop_gdb.sh --yes --test'
	num_logs="$(find "$(./lib/eval_lib.sh "echo \$CFG_LOGS_PATH")" -type f | wc -l)"
	if [ "$num_logs" -gt "2" ]
	then
		echo " OK"
	else
		echo " FAIL"
		cat ./logs/test_gdb.txt
		echo "Error: loop_gdb.sh did not create enough logfiles"
		echo "       found $num_logs logs expected 3"
		echo "       did the server restart properly?"
		fail
	fi
}

function test_status_size_check() {
	create_server "status_size"
	mkdir -p logs/ddos
	local x
	for x in {1..150}
	do
		head -c 10MB /dev/urandom > logs/ddos/ddos_"$x".txtA
	done
	echo 'auto_cleanup_old_local_data=1' >> server.cnf
	./status.sh
	if ./status.sh | grep -q WARNING
	then
		echo "Error: ./status.sh threw a WARNING"
		fail
	fi
}

function create_server() {
	if [ "$#" != "1" ]
	then
		echo "create_server: 1 arg required"
		fail
	fi
	local servername="$1"
	local serverdir="$testdir/$servername"
	mkdir -p "$serverdir" || fail
	cp ./*.sh "$serverdir"
	mkdir -p "$serverdir"/lib
	cp lib/*.sh "$serverdir"/lib
	cp -r lib/include "$serverdir"/lib
	cp -r bin/ "$serverdir"
	cp -r .git "$serverdir"
	cp .gitignore "$serverdir"
	cd "$serverdir" || fail
	echo "$twexec" > autoexec.cfg
	echo "$servercnf" > server.cnf
	cd "$root_dir" || fail
	num_servers="$((num_servers+1))"
}

test_exec_all_servers
test_loop_gdb
test_status_size_check

clear_testdir

