#!/bin/bash

function format_line() {
	local line="$1"
	echo "echo \"${line//\"/\\\"}\""
}

function format_file() {
	file="$1"
	if [ ! -f "$file" ]
	then
		echo "echo \"Error: file '$file' not found.\""
		exit 1
	fi
	while IFS= read -r line;
	do
		format_line "$line"
	done < "$file"
}

if [ "$#" == "0" ]
then
	while IFS=$'\n' read -r line;
	do
		format_line "$line"
	done
	exit 0
fi

for arg in "$@"
do
	if [ "$arg" == "--help" ] || [ "$arg" == "-h" ]
	then
		echo "usage: $(basename "$0") [FILE..]"
		echo "description:"
		echo "  wraps every line of given file in a echo"
		echo "  so it can be viewed as teeworlds admin"
		echo "  using the rcon command 'exec file.txt'"
		echo "  if no file is given it uses stdin"
		exit 0
	else
		format_file "$arg"
	fi
done

