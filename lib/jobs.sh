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
    echo "usage: $0 {status|restart|stop|start|edit|run} <job>"
    echo "usage: $0 [list|kill_all|help]"
    exit
fi

check_server_dir

mode="$1"
jobname="$2"
jobs_dir="$(pwd)/lib/var/jobs/global"
jobs_dir_on="$(pwd)/lib/var/jobs/global/on"
jobs_dir_off="$(pwd)/lib/var/jobs/global/off"
job="$jobs_dir_on/$jobname"
if [ ! -f "$job" ]
then
    job="$jobs_dir_off/$jobname"
fi
mkdir -p "$jobs_dir"
mkdir -p "$jobs_dir_on"
mkdir -p "$jobs_dir_off"

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
    tree "$jobs_dir"
elif [ "$mode" == "edit" ]
then
    edit_job
elif [ "$mode" == "run" ]
then
    edit_job
    "$job"
else
    err "invalid argument"
    exit 1
fi

