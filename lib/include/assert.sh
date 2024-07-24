# compare two strings and ensure they match or crash
# matching node order of actual, expected, [message]  https://nodejs.org/api/assert.html#assertequalactual-expected-message
# matching rust order of actual, expexted https://users.rust-lang.org/t/assert-eq-expected-and-actual/20304/3
#
# @param actual
# @param expected
# @param [message]
assert_eq() {
	local actual="$1"
	local expected="$2"
	local message="${3:-}"
	[ "$actual" = "$expected" ] && return

	printf 'assertion error! %s\n' "$message" 1>&2
	printf ' expected: %s\n' "$expected" 1>&2
	printf '      got: %s\n' "$actual" 1>&2
}

