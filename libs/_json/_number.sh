#!/usr/bin/env bash

# source grammar from https://ecma-international.org/publications-and-standards/standards/ecma-404/
# digit := 0-9           ╭─>────────────────╮
#  start ─┬─┬─ 0 ────┬───┴─ . ──┬─ digit ─>┬┴┬─────────────────┬─ ╳
#     │   │ │       ╭╯          ^          │ ├ e ╮     ╭─────<─┤
#     ╰ - ╯ ╰ 1-9 ─┬┴─ digit >╮ ╰──────────╯ ╰ E ┤╭ + ╮│       │
#                  ^          │                  ╰┼───┼┴ digit ╯
#                  ╰──────────╯                   ╰ - ╯
#       0     1/2       3  4        5          6    7     8

_n_8() {
  local CHAR="${1:0:1}"
  local REMAINDER="${1:1}"
  [ -z "$CHAR" ] && printf "%s\n" "$2" && return 0
  local value="${2}${CHAR}"
  case "$CHAR" in
    [0-9])
      value="$(
        _n_8 "$REMAINDER" "$value"
      )" || return "$?"
      ;;
    *)
      return 99
      ;;
  esac
  printf "%s\n" "$value"
}

_n_7() {
  local CHAR="${1:0:1}"
  local REMAINDER="${1:1}"
  [ -z "$CHAR" ] && return 99 #  not a valid termination state
  local value="${2}${CHAR}"
  case "$CHAR" in
    [0-9])
      value="$(
        _n_8 "$REMAINDER" "$value"
      )" || return "$?"
      ;;
    *)
      return 99
      ;;
  esac
  printf "%s\n" "$value"
}

_n_6() {
  local CHAR="${1:0:1}"
  local REMAINDER="${1:1}"
  [ -z "$CHAR" ] && return 99 #  not a valid termination state
  local value="${2}${CHAR}"
  case "$CHAR" in
    [0-9])
      value="$(
        _n_8 "$REMAINDER" "$value"
      )" || return "$?"
      ;;
    + | -)
      value="$(
        _n_7 "$REMAINDER" "$value"
      )" || return "$?"
      ;;
    *)
      return 99
      ;;
  esac
  printf "%s\n" "$value"
}

_n_5() {
  local CHAR="${1:0:1}"
  local REMAINDER="${1:1}"
  [ -z "$CHAR" ] && printf "%s\n" "$2" && return 0
  local value="${2}${CHAR}"
  case "$CHAR" in
    [0-9])
      value="$(
        _n_5 "$REMAINDER" "$value"
      )" || return "$?"
      ;;
    e | E)
      value="$(
        _n_6 "$REMAINDER" "$value"
      )" || return "$?"
      ;;
    *)
      return 99
      ;;
  esac
  printf "%s\n" "$value"
}

_n_4() {
  local CHAR="${1:0:1}"
  local REMAINDER="${1:1}"
  [ -z "$CHAR" ] && return 99 #  not a valid termination state
  local value="${2}${CHAR}"
  case "$CHAR" in
    [0-9])
      value="$(
        _n_5 "$REMAINDER" "$value"
      )" || return "$?"
      ;;
    *)
      return 99
      ;;
  esac
  printf "%s\n" "$value"
}

_n_3() {
  local CHAR="${1:0:1}"
  local REMAINDER="${1:1}"
  [ -z "$CHAR" ] && printf "%s\n" "$2" && return 0
  local value="${2}${CHAR}"
  case "$CHAR" in
    [0-9])
      value="$(
        _n_3 "$REMAINDER" "$value"
      )" || return "$?"
      ;;
    .)
      value="$(
        _n_4 "$REMAINDER" "$value"
      )" || return "$?"
      ;;
    e | E)
      value="$(
        _n_6 "$REMAINDER" "$value"
      )" || return "$?"
      ;;
    *)
      return 99
      ;;
  esac
  printf "%s\n" "$value"
}

_n_2() {
  local CHAR="${1:0:1}"
  local REMAINDER="${1:1}"
  [ -z "$CHAR" ] && printf "%s\n" "$2" && return 0
  local value="${2}${CHAR}"
  case "$CHAR" in
    [0-9])
      value="$(
        _n_3 "$REMAINDER" "$value"
      )" || return "$?"
      ;;
    .)
      value="$(
        _n_4 "$REMAINDER" "$value"
      )" || return "$?"
      ;;
    e | E)
      value="$(
        _n_6 "$REMAINDER" "$value"
      )" || return "$?"
      ;;
    *)
      return 99
      ;;
  esac
  printf "%s\n" "$value"
}

_n_1() {
  local CHAR="${1:0:1}"
  local REMAINDER="${1:1}"
  [ -z "$CHAR" ] && printf "%s\n" "$2" && return 0
  local value="${2}${CHAR}"
  case "$CHAR" in
    .)
      value="$(
        _n_4 "$REMAINDER" "$value"
      )" || return "$?"
      ;;
    e | E)
      value="$(
        _n_6 "$REMAINDER" "$value"
      )" || return "$?"
      ;;
    *)
      return 99
      ;;
  esac
  printf "%s\n" "$value"
}

_n_0() {
  local CHAR="${1:0:1}"
  local REMAINDER="${1:1}"
  [ -z "$CHAR" ] && return 99 #  not a valid termination state
  local value="${2}${CHAR}"
  case "$CHAR" in
    0)
      value="$(
        _n_1 "$REMAINDER" "$value"
      )" || return "$?"
      ;;
    [1-9])
      value="$(
        _n_2 "$REMAINDER" "$value"
      )" || return "$?"
      ;;
    *)
      return 99
      ;;
  esac
  printf "%s\n" "$value"
}

_number() {
  #  set -x
  local CHAR="${1:0:1}"
  local REMAINDER="${1:1}"
  local value="$CHAR"

  case "$CHAR" in
    -)
      value="$(
        _n_0 "$REMAINDER" "$value"
      )" || return "$?"
      ;;
    [1-9])
      value="$(
        _n_2 "$REMAINDER" "$value"
      )" || return "$?"
      ;;
    0)
      value="$(
        _n_1 "$REMAINDER" "$value"
      )" || return "$?"
      ;;
    *)
      return 99
      ;;
  esac
  printf "%s\n" "$value"
}
