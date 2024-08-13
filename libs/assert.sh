#shellcheck source=./logging.sh
source ./libs/logging.sh

assert_string_eq() {
  local s1 s2
  s1="$1"
  s2="$2"
  if [ "$s1" != "$s2" ]; then
    elog -l ERROR "assertion failed: '$s1' != '$s2'"
    return 1
  else
    elog -l INFO "assertion passed: '${s1:0:250}' == '${s2:0:250}'"
  fi
}

assert_error() {
  local fn
  fn="$1"
  shift
  if $fn "$@"; then
    elog -l ERROR "assertion failed in $fn: expected error but got none"
    return 1
  else
    elog -l INFO "assertion passed in $fn: expected was expected"
  fi
}