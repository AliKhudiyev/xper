#!/usr/bin/env bash

assert_equals(){
    local expected="$1"
    local actual="$2"
    local message="$3"

    if [[ "$expected" != "$actual" ]]; then
        echo "  FAIL: $message"
        echo "  Expected: '$expected'"
        echo "  Actual:   '$actual'"
        exit 1
    fi
}
