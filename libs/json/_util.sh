#!/usr/bin/env bash

_ERROR_SYNTAX() {
  printf "SYNTAX ERROR: Unexpected character at position %d: '%s'\n" "$1" "$2" >&2
  return 99
}

save_data() {
  local path="$1"
  local value="$2"
  printf "%s=%s\n" "$path" "${value@Q}" >> "$__DATAFILE__"
}

slurp_whitespace() {
  local CHAR="${1:0:1}"
  local raw_input="$1"
  local first_char=0
  case "$CHAR" in
    [[:space:]])
      first_char="$(_next_token_index "$raw_input")"
      ;;
    *) ;;
  esac

  printf "%s" "${raw_input:$first_char}"
}

_next_token_index() {
  local trim_plus_1="${1#*[![:space:]]}"
  local start="$((${#1} - ${#trim_plus_1} - 1))"
  printf "%d" "$start"
}
