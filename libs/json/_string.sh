#!/usr/bin/env bash

export GLOBAL_COUNTER=0

# shellcheck source=./_util.sh
source ./libs/json/_util.sh

# source grammar from https://ecma-international.org/publications-and-standards/standards/ecma-404/
#
#    valid_char  = any char except " or \
#    4dx = 4 digit hex for UTF-32
#               (?:)  0     1/2
#  ┌─────┐                                         x x
#  │start┼────► " ─────────────────────────► " ───► x
#  └─────┘      │ ┌───────────────────────┐  │     x x
#               │ ▼                       ▲  ▲
#               ╰─┴─┬────► valid_char ──┬─┴──╯
#                   ▼                   ▲
#                   ╰─ \ ─┬─ " ──────┬──╯
#                         ▼          ▲
#                         ├─ \ ───►──┤
#                         ├─ / ───►──┤
#                         ├─ b ───►──┤
#                         ├─ f ───►──┤
#                         ├─ n ───►──┤
#                         ├─ r ───►──┤
#                         ├─ t ───►──┼
#                         ╰─ u 4dx ─►╯
#                              2.5^
_s_2_5() {
  # our restrictions here are my interpretation of json spec
  # which is case is insensitive and any combination of 31 bits is ok
  # so long as it is valid hex
  local REMAINDER CHAR value
  TO_PARSE="${1}"
  value="${2}"
  for i in {1..4}; do
    CHAR="${TO_PARSE:0:1}"
    REMAINDER="${TO_PARSE:1}"
    value="${value}${CHAR}"
    TO_PARSE="$REMAINDER"
    case "$CHAR" in
    [0-9a-fA-F]) ;;
    *)
      return 99
      ;;
    esac
  done
  value="$(_s_2 "$REMAINDER" "$value")" || return "$?"
  printf "%s" "$value"
}

_s_2() {
  _s_1 "$@"
}

_s_1() {
  local CHAR="${1:0:1}"
  local REMAINDER="${1:1}"
  [ -z "$CHAR" ] && return 99 #  not a valid termination state
  local value="${2}${CHAR}"
  case "$CHAR" in
  \")
    value="${value%\"}"
    ;;
  \\)
    value="$(
      _s_0 "$REMAINDER" "$value"
    )" || return "$?"
    ;;
  *)
    value="$(
      _s_1 "$REMAINDER" "$value"
    )" || return "$?"
    ;;
  esac
  printf "%s" "$value"
}

_s_0() {
  local CHAR="${1:0:1}"
  local REMAINDER="${1:1}"
  local value="${2}${CHAR}"
  case "$CHAR" in
  \" | \\ | \/ | b | f | n | r | t | 8)
    value="$(
      _s_2 "$REMAINDER" "$value"
    )" || return "$?"
    ;;
  u)
    value="$(
      _s_2_5 "$REMAINDER" "$value"
    )" || return "$?"
    ;;
  *)
    return 99
    ;;
  esac
  printf "%s" "$value"
}

_string() {
  # quote has been recognized but not stripped yet
  local CHAR="${1:1:1}" # skip the quote
  local REMAINDER="${1:2}"
  [ "$CHAR" = '"' ] && [ -z "$REMAINDER" ] && return 0 # empty string
  local value="$CHAR"
  case "$CHAR" in                                      # we are at the first char after the quote
  \\)
    value="$(
      _s_0 "$REMAINDER" "$value"
    )" || return "$?"
    ;;
  *)
    value="$(
      _s_1 "$REMAINDER" "$value"
    )" || return "$?"
    ;;
  esac
  printf "%s\n" "$value"
}