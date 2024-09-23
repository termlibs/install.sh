#!/usr/bin/env bash

# shellcheck source=./_string.sh
source ./libs/json/_string.sh

# shellcheck source=./_number.sh
source ./libs/json/_number.sh

# shellcheck source=./_array.sh
source ./libs/json/_array.sh

# shellcheck source=./_root.sh
source ./libs/json/_root.sh

# source grammar from https://ecma-international.org/publications-and-standards/standards/ecma-404/
#               ┌─────────────────────────────┐
#               ▲        0                     ▼
#   start ──► { ┴─┬─► string ─► : ─► value ─┬─┴► } ──► end
#                 ▲                         ▼
#                 └──────────── , ◄─────────┘
#

_o_0() {
  # parse the key
  local key_value value next R
  eval R="$(_string "$2")" || return "$?"
  key_value=${R[0]}
  next=${R[1]}
  local current_path="${1}${KEY_DIVIDER}${key_value}"
  next="$(slurp_whitespace "${next}")" # remove whitespace
  # next character _must be a colon
  [ "${next:0:1}" = ':' ] || return 99 # remove whitespace
  eval R="$(parse_json "$current_path" "$(slurp_whitespace "${next:1}")")" || return "$?"
  value=${R[0]}
  next=${R[1]}
  next="$(slurp_whitespace "$next")" # remove whitespace
  case "${next:0:1}" in
  ,)
    # TODO:  this munks up the keys, we can't just reuse the above so this is next thing that needs fixies
    # do it again!
    eval R="$(_o_0 "$current_path" "${next:1}")" || return "$?"
    value=${R[0]}
    next=${R[1]}
    ;;
  \}) ;;
  *)
    return 99
    ;;
  esac
  printf '( %s %s )' "${value@Q}" "${next@Q}"
}

_object() {
  set -x
  local value next R
  local current_path="$1"
  local TRIMMED="$(slurp_whitespace "${2:1}")" # remove bracket and slurp whitespace
  local CHAR="${TRIMMED:0:1}"
  local REMAINDER="${TRIMMED:1}"
  [ "$CHAR" = '}' ] && [ -z "$REMAINDER" ] && return 0 # empty object
  case "$CHAR" in                                      # we are at the first char after the quote
  \")
    eval R="$(_o_0 "$current_path" "$TRIMMED")" || return "$?"
    value=${R[0]}
    next=${R[1]}
    ;;
  *)
    return 99
    ;;
  esac
  printf '( %s %s )' "${value@Q}" "${next@Q}"
}
