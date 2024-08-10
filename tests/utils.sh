
_ansii_red="\e[1;31m"
_ansii_yellow="\e[1;33m"
_ansii_green="\e[1;32m"
_ansii_reset="\e[0m"
_ansii_bold="\e[1m"

elog() {
  local opts level _ansii_red _ansii_yellow _ansii_green _ansii_reset prefix
  opts="$(getopt -o l: --long level: -n 'assert_string_eq' -- "$@")"
  [ $? -ne 0 ] && return 1
  eval set -- "$opts"
  while true; do
    case "$1" in
      -l|--level)
        level="$2"
        shift 2
        ;;
      --)
        shift
        break
        ;;
      *)
        return 1
        ;;
    esac
  done
  if [[ "$TERM" = *"color" ]]; then
    case "$level" in
      INFO)
        level="${_ansii_green@E}$level${_ansii_reset@E}"
        ;;
      WARN)
        level="${_ansii_yellow@E}$level${_ansii_reset@E}"
        ;;
      ERROR)
        level="${_ansii_red@E}$level${_ansii_reset@E}"
        ;;
      *)
        level="${_ansii_reset@E}$level${_ansii_reset@E}"
        ;;
    esac
  fi
  prefix="$(printf "%s [%6s]: " "$(date +%H:%M:%S)" "$level")"
  printf "%s: %s\n"  "${prefix@P}" "$*"  >&2
}