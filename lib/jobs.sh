#!/bin/bash

if [ ! -f lib/lib.sh ]
then
	echo "Error: lib/lib.sh not found!"
	echo "make sure you are in the root of the server repo"
	exit 1
fi

source lib/lib.sh

if [ "$#" == "0" ] || [ "$1" == "--help" ] || [ "$1" == "-h" ] || [ "$1" == "help" ]
then
	# TODO: add optional global default local argument to list
	# global would go through all server dirs and list there as well
	# echo "usage: $0 {create|list} {global|local} <job>"
	echo "usage: $0 create {global|local} <job>"
	echo "usage: $0 {status|restart|stop|start|interact|i|run|edit} <job>"
	echo "usage: $0 [list|kill_all|fix|help]"
	echo "parameters:"
	echo "  status      show status of background job"
	echo "  restart     restart background job"
	echo "  stop        stop background job"
	echo "  start       start background job"
	echo "  interact    pull background job to foreground"
	echo "  i           same as interact"
	echo "  run         run foreground (for tests and own background tools)"
	echo "  edit        edit job file"
	echo "  list        list all jobs off and on"
	echo "  fix         trys to repair a broken state" # TODO: check all if running and if not move to off dir
	exit
fi

check_server_dir
JOB_PATH="${SCRIPT_ROOT}/lib/var/jobs"
function is_job() {
	if [ -f "$JOB_PATH/global/on/$jobname" ] || [ -f "$JOB_PATH/global/off/$jobname" ]
	then
		scope="global"
	elif [ -f "$JOB_PATH/local/on/$jobname" ] || [ -f "$JOB_PATH/local/off/$jobname" ]
	then
		scope="local"
	else
		return 1
	fi
	return 0
}

mode="$1"
scope="global"
jobname="$2"
is_job "$jobname" # updates scope on found
if [ "$mode" == "create" ]
then
	scope="$2"
	jobname="$3"
	if [ "$scope" != "global" ] && [ "$scope" != "local" ] && [ "$#" -gt "1" ]
	then
		err "invalid scope '$scope' has to be 'global' or 'local'"
		exit 1
	fi
	if [ "$jobname" == "" ]
	then
		err "Missing argument jobname"
		err "usage: $0 create {global|local} <job>"
		exit 1
	fi
	if is_job "$jobname"
	then
		err "job '$jobname' already exists."
		exit 1
	else
		log "creating job '$jobname'"
	fi
elif [ "$#" -eq "2" ]
then
	# assume scope when 2 args
	if is_job "$jobname"
	then
		test
	else
		err "job '$jobname' not found."
		exit 1
	fi
fi
jobs_dir="$JOB_PATH/$scope"
jobs_dir_on="$JOB_PATH/$scope/on"
jobs_dir_off="$JOB_PATH/$scope/off"
job="$jobs_dir_on/$jobname"
job_off="$jobs_dir_off/$jobname"
job_on="$jobs_dir_on/$jobname"
job_id="job-$scope-$jobname-$SERVER_UUID"
if [ ! -f "$job" ]
then
	job="$jobs_dir_off/$jobname"
fi
if [ "$#" -gt "1" ]
then
	mkdir -p "$jobs_dir"
	mkdir -p "$jobs_dir_on"
	mkdir -p "$jobs_dir_off"
fi

read -rd '' job_template << EOF
#!/bin/bash
while true;
do
	echo "this is a sample job"
	sleep 3
done
EOF

function edit_job() {
	if [ ! -f "$job" ]
	then
		echo "$job_template" > "$job"
	fi
	edit_file "$job"
	chmod +x "$job"
}

function show_status() {
	if ! pgrep -f "$job_id" >/dev/null
	then
		err "job '$jobname' is not running"
		exit 1
	else
		suc "job '$jobname' is running"
	fi
}

function check_kill() {
	# cleans in fs as on marked jobs that are actually dead
	if [ -f "$job_on" ]
	then
		if ! pgrep -f "$job_id" >/dev/null
		then
			log "cleaning stopped job '$jobname' ..."
			mv "$job_on" "$job_off" || { err "Error: failed to cleanly stop job '$jobname'"; exit 1; }
		fi
	fi
}

if [ "$mode" == "list" ]
then
	if [ ! -d "$jobs_dir" ]
	then
		log "no jobs yet"
		wrn "job dir not found '$jobs_dir'"
		exit
	fi
	tree "$JOB_PATH"
elif [ "$mode" == "edit" ] || [ "$mode" == "create" ]
then
	edit_job
elif [ "$mode" == "status" ]
then
	show_status
elif [ "$mode" == "stop" ]
then
	if pgrep -f "$job_id" >/dev/null
	then
		screen -r "$job_id" -X quit
	else
		wrn "job '$jobname' is already off"
	fi
	if [ -f "$job_on" ]
	then
		suc "stopped job '$jobname'"
		mv "$job_on" "$job_off" || { err "Error: failed to cleanly stop job '$jobname'"; exit 1; }
	fi
elif [ "$mode" == "start" ]
then
	# prgep does not find screens
	# shellcheck disable=SC2009
	proc="$(ps aux | grep "$job_id" | grep -v grep)"
	if [ "$proc" != "" ]
	then
		err "Error: job '$jobname' is already running:"
		echo "$proc"
		exit 1
	fi
	if [ ! -f "$job_off" ]
	then
		err "Critical error: job '$jobname' is not off"
		err "Your system seems to be in a erronous state"
		exit 1
	fi
	mv "$job_off" "$job_on" || { err "Error: failed to start job '$jobname'"; exit 1; }
	log "starting job '$jobname' ..."
	# echo "job_id=$job_id"
	# echo "job=$job"
	screen -AmdS "$job_id" "$job_on"
	show_status
elif [ "$mode" == "interact" ] || [ "$mode" == "i" ]
then
	show_status
	screen -r "$job_id"
	check_kill
elif [ "$mode" == "run" ]
then
	"$job"
else
	err "invalid argument"
	exit 1
fi

