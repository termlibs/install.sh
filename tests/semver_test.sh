#!/usr/bin/env bash
# shellcheck disable=SC3043,SC2001 source=./semver.sh
# SCRIPTSH_VERSION=0.0.1
# sourced from https://github.com/warehouseman/semver_shell/blob/master/semver.sh
# then linted with shellcheck and tweaked for preferences
source "$(dirname "${BASH_SOURCE[0]}")/semver.sh"

A=v1.3.2
B=v2.3.2
C=v1.4.2
D=v1.3
E=v1.3.2-a.1
F=v1.3.2-b.2
G=v1.2.3
H=2
I=1.3.0
J=3a3a3

assert() {
  local result
  result="$(eval "$1")"
  if [ "$result" != "$2" ]; then
    echo "During evaluation of \"$1\""
    echo "Expected \"$2\", but got \"$result\""
    exit 1
  fi
}

assert_code() {
  local code
  eval "$1"
  code="$?"
  if [ "$code" -ne "$2" ]; then
    echo "During evaluation of \"$1\""
    echo "Expected exit code $2, but got $code"
    exit 1
  fi
}

# trailing spaces indicate we have no extra/special version parts
assert "semver_parse \"$A\"" "1 3 2 "
assert "semver_parse \"$B\"" "2 3 2 "
assert "semver_parse \"$C\"" "1 4 2 "
assert "semver_parse \"$D\"" "1 3 0 "
assert "semver_parse \"$E\"" "1 3 2 a.1"
assert "semver_parse \"$F\"" "1 3 2 b.2"
assert "semver_parse \"$G\"" "1 2 3 "
assert "semver_parse \"$H\"" "2 0 0 "

assert_code "semver_eq $A $A" 0
assert_code "semver_eq $A $B" 1
assert_code "semver_eq $D $I" 0

assert_code "semver_lt $A $B" 0
assert_code "semver_lt $I $H" 0
assert_code "semver_lt $E $F" 0

assert_code "semver_gt $A $D" 0
assert_code "semver_gt $H $A" 0
assert_code "semver_gt $F $E" 0

assert_code "semver_validate $A" 0
assert_code "semver_validate $J" 1

assert "semver_bump_to $F major" "2.0.0"
assert "semver_bump_to $F minor" "1.4.0"
assert "semver_bump_to $F patch" "1.3.3"
