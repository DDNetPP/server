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
    echo "usage: $0 create {global|local} <job>"
    echo "usage: $0 {status|restart|stop|start|run|edit} <job>"
    echo "usage: $0 [list|kill_all|help]"
    echo "parameters:"
    echo "  status      show status of background job"
    echo "  restart     restart background job"
    echo "  stop        stop background job"
    echo "  start       start background job"
    echo "  run         run foreground (for tests and own background tools)"
    echo "  edit        edit job file"
    exit
fi

check_server_dir
JOB_PATH="$(pwd)/lib/var/jobs"
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

if [ "$mode" == "list" ]
then
    if [ ! -d "$jobs_dir" ]
    then
        log "no jobs yet"
        exit
    fi
    tree "$jobs_dir"
elif [ "$mode" == "edit" ] || [ "$mode" == "create" ]
then
    edit_job
elif [ "$mode" == "run" ]
then
    if is_job "$jobname"
    then
        "$job"
    else
        err "job '$jobname' not found"
        exit 1
    fi
else
    err "invalid argument"
    exit 1
fi

