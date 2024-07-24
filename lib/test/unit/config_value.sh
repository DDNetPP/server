#!/bin/bash

if [ ! -f lib/lib.sh ]
then
	echo "Error: lib/lib.sh not found!"
	echo "make sure you are in the root of the server repo"
	exit 1
fi

source lib/lib.sh

log -n "tw_config.sh [get_tw_config_value] ... "

assert_eq "$(get_tw_config_value 'sv_name "foo"')" "foo" "simple double quotes"
assert_eq "$(get_tw_config_value 'sv_name foo')" "foo" "simple string without quotes"
assert_eq "$(get_tw_config_value 'sv_name foo bar')" "foo bar" "two word string without quotes"
assert_eq "$(get_tw_config_value 'sv_name foo # hello')" "foo" "string no quotes with comment"
assert_eq "$(get_tw_config_value 'sv_name "foo" # hello')" "foo" "string quotes with comment"
assert_eq "$(get_tw_config_value 'sv_name "foo bar" # hello')" "foo bar" "multi word string quotes with comment"
assert_eq "$(get_tw_config_value 'sv_name "foo # bar" # hello')" "foo # bar" "multi word string quotes with comment and hash tag"
assert_eq "$(get_tw_config_value 'sv_name "foo \" bar" # hello')" 'foo " bar' "qouted multi word string with escaped quote"
# shellcheck disable=SC1003
assert_eq "$(get_tw_config_value 'sv_name "foo \\" bar" # hello')" 'foo \' "escaped backslash should unescape quote"
# assert_eq "$(get_tw_config_value 'sv_name a\"a')" 'a\"a' "escapes only work in strings"

echo "OK"

