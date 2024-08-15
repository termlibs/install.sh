#!/usr/bin/env bash

# shellcheck source=./_string.sh
source ./libs/json/_string.sh

# shellcheck source=./_number.sh
source ./libs/json/_number.sh

# shellcheck source=./_array.sh
source ./libs/json/_array.sh

# shellcheck source=./_root.sh



# source grammar from https://ecma-international.org/publications-and-standards/standards/ecma-404/
#               ┌─────────────────────────────┐
#               ▲                             ▼
#   start ──► { ┴─┬─► string ─► : ─► value ─┬─┴► } ──► end
#                 ▲                         ▼
#                 └──────────── , ◄─────────┘
#                      0      1/2    3

_o_2() {
  local TRIMMED="$(slurp_whitespace "$1")"
  local CHAR="${TRIMMED:0:1}"
  local REMAINDER="${TRIMMED:1}"
  [ -z "$CHAR" ] && return 0
  case "$CHAR" in
  \")
    value="$(
      _string "$REMAINDER"
    )" || return "$?"
    ;;
  *)
    return 99
    ;;
  esac
  printf "%s\n" "$value"
}

_o_0() {
  # parse the key
  local key_value
  key_value="$(_string "$1")" || return "$?"
  _KEY_PATH+=("$key_value")
  local TRIMMED="${1:$((${#key_value} + 2))}"  # get to the next char after the quote
  TRIMMED="$(slurp_whitespace "$TRIMMED")" # remove whitespace
  # next character _must be a colon
  [ "${TRIMMED:0:1}" = ':' ] || return 99
  value="$(parse_json "${TRIMMED:1}")" || return "$?"
  _DATA_OBJECT["${_KEY_PATH[*]}"]="$value"
}

_object() {
  local TRIMMED="$(slurp_whitespace "${1:1}")" # remove bracket and slurp whitespace
  local CHAR="${TRIMMED:0:1}"
  local REMAINDER="${TRIMMED:1}"
  [ "$CHAR" = '}' ] && [ -z "$REMAINDER" ] && return 0 # empty object
  case "$CHAR" in # we are at the first char after the quote
  \")
    _o_0 "$TRIMMED" || return "$?"
    ;;
  *)
    return 99
    ;;
  esac
}
