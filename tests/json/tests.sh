#!/usr/bin/env bash

# shellcheck source=./libs/json.sh
trap 'set +x' EXIT
source "./libs/json/main.sh"
source ./tests/utils.sh

assert_string_eq() {
  local s1 s2
  s1="$1"
  s2="$2"
  if [ "$s1" != "$s2" ]; then
    elog -l ERROR "assertion failed: '$s1' != '$s2'"
    return 1
  else
    elog -l INFO "assertion passed: '$s1' == '$s2'"
  fi
}

assert_error() {
  local fn
  fn="$1"
  shift
  if $fn "$@"; then
    elog -l ERROR "assertion failed: expected error"
    return 1
  else
    elog -l INFO "assertion passed: expected error"
  fi
}

log_test() {

  elog -l INFO "Running test $((test_idx++)): ${_T}"

}

set +x
set +e
trap 'set +xe' EXIT
current_fn="_parse_token"
{
  _T="{ \"1\": 2 }"
  log_test
  assert_string_eq "$(_parse_token "$_T")" "object"
  _T="\"{ \\\"1\\\": 2 }\""
  log_test
  assert_string_eq "$(_parse_token "$_T")" "string"
  _T="1.2"
  log_test
  assert_string_eq "$(_parse_token "$_T")" "number"
  _T="2"
  log_test
  assert_string_eq "$(_parse_token "$_T")" "number"
  _T="[ \"1\", 2 ]"
  log_test
  assert_string_eq "$(_parse_token "$_T")" "array"
  _T="[ \"1\", 2 "
  log_test
  assert_error _parse_token "$_T"
  _T="null"
  log_test
  assert_string_eq "$(_parse_token "$_T")" "null"
  _T="nult"
  log_test
  assert_error _parse_token "$_T"
}
