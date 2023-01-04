#!/bin/sh

# source lib/env_san.sh

# supp file paths are relative to the bin/ directory

export UBSAN_OPTIONS=suppressions=../lib/supp/ubsan.supp:log_path=./SAN:print_stacktrace=1:halt_on_errors=0
export ASAN_OPTIONS=log_path=./SAN:print_stacktrace=1:check_initialization_order=1:detect_leaks=1:halt_on_errors=0
export LSAN_OPTIONS=suppressions=../lib/supp/lsan.supp
