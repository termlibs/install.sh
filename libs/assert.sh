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

assert_exit_code() {
  opts="$(getopt -o "c:" --long code: -- "$@")"
  [ $? -eq 0 ] || return 1
  eval set -- "$opts"
  local code="-1"
  while true; do
    case "$1" in
      --code|-c)
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
  if [ "$_rc" -ne "$code" ]; then
    elog -l ERROR "assertion failed in $fn: expected return code $code but got $_rc"
    return 1
  else
    elog -l INFO "assertion passed in $fn: return code was as expected ($_rc)"
  fi
}
