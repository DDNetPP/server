#!/bin/bash

if [ ! -f lib/lib.sh ]
then
	echo "Error: lib/lib.sh not found!"
	echo "make sure you are in the root of the server repo"
	exit 1
fi

source lib/lib.sh


function _test_pure_bash_bible() {
	log -n "pure-bash-bible.sh [reverse_array 1/2] ... "

	if ! diff <(reverse_array 1 2 3) <(printf '3\n2\n1\n')
	then
		echo "FAIL"
		err "reverse_array failed"
		exit 1
	else
		echo "OK"
	fi

	log -n "pure-bash-bible.sh [reverse_array 2/2] ... "

	local arr=(red blue green)
	if ! diff <(reverse_array "${arr[@]}") <(printf 'green\nblue\nred\n')
	then
		echo "FAIL"
		err "reverse_array failed"
		exit 1
	else
		echo "OK"
	fi
}

# Tests are passing but the function is unused for now
# Gotta save those millisecs runtime of not loading the function
# _test_pure_bash_bible

