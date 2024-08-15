#!/usr/bin/env bash
_SCRIPT_SH_VERSION=0.0.1

# source grammar from https://ecma-international.org/publications-and-standards/standards/ecma-404/
# start ──┬───► object ────┬─► end
#         ├───► array ──►──┤
#         ├───► number ─►──┤
#         ├───► string ─►──┤
#         ├───► true  ──►──┤
#         ├───► false ──►──┤
#         ╰───► null  ──►──╯




parse_json() {
  set -x
  local TRIMMED="$(slurp_whitespace "$1")"
  local CHAR="${TRIMMED:0:1}"
  local RAW_INPUT="$TRIMMED"
  local value=""
  case "$CHAR" in
    '"')
      _string "$RAW_INPUT" || return "$?"
      ;;
    [[:digit:]] | '-')
      _number "$RAW_INPUT" || return "$?"
      ;;
    "t")
      _true "$RAW_INPUT" || return "$?"
      ;;
    "f")
      _false "$RAW_INPUT" || return "$?"
      ;;
    "n")
      _null "$RAW_INPUT" || return "$?"
      ;;
    '{')
      _object "$RAW_INPUT" || return "$?"
      ;;
    '[')
      _array "$RAW_INPUT" || return "$?"
      ;;
    *)
      _ERROR_SYNTAX "$GLOBAL_COUNTER" "$FIRST_CHAR" >&2
      return 99
      ;;
  esac
  printf "%s\n" "$value"
}

_s_consume() {
  [ -z "$1" ] && return 1
  printf "%s" "$2$1"
}