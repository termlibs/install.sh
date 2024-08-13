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
  opts="$(getopt -o "" --long code: -- "$@")"
  [ $? -eq 0 ] || return 1
  eval set -- "$opts"
  local code=""
  while true; do
    case "$1" in
      --code)
        code="$2"
        shift 2
        ;;
      --)
        shift
        break
        ;;
    esac
  done
  local fn _rc
  fn="$1"
  shift
  $fn "$@" #> /dev/null 2>&1
  _rc="$?"
  if [ "$_rc" -eq 0 ]; then
    if [ -n "$code" ]; then
      elog -l ERROR "assertion failed in $fn: expected error code $code but got none"
      return 1
    else
      elog -l ERROR "assertion failed in $fn: expected error but got none"
    fi
    return 1
  else
    if [ -n "$code" ]; then
      if [ "$code" != "$_rc" ]; then
        elog -l ERROR "assertion failed in $fn: expected error code $code but got $_rc"
        return 1
      fi
      elog -l INFO "assertion passed in $fn: expected error code $code and got error code $_rc"
    else
      elog -l INFO "assertion passed in $fn: expected error"
    fi
  fi
}
