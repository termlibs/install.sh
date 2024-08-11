#!/usr/bin/env bash

# source grammar from https://ecma-international.org/publications-and-standards/standards/ecma-404/
source ./libs/json/_util.sh

# state machine for numbers
# digit := 0-9           ╭─>────────────────╮
#  start ─┬─┬─ 0 ────┬───┴─ . ──┬─ digit ─>┬┴┬─────────────────┬─ ╳
#     │   │ │       ╭╯          ^          │ ├ e ╮     ╭─────<─┤
#     ╰ - ╯ ╰ 1-9 ─┬┴─ digit >╮ ╰──────────╯ ╰ E ┤╭ + ╮│       │
#                  ^          │                  ╰┼───┼┴ digit ╯
#                  ╰──────────╯                   ╰ - ╯
#   0  1      2/3        4   5      6          7    8     9     10

_n_9() {
  local CHAR="${1:0:1}"
  local REMAINDER="${1:1}"
  _n_init $CHAR || return # return if empty
  case "$CHAR" in
    [0-9])
      _n_9 "$REMAINDER"
      ;;
    *)
      return 99
      ;;
  esac
}

_n_8() {
  local CHAR="${1:0:1}"
  local REMAINDER="${1:1}"
  _n_init $CHAR || return # return if empty
  case "$CHAR" in
    [0-9])
      _n_9 "$REMAINDER"
      ;;
    *)
      return 99
      ;;
  esac
}

_n_7() {
  local CHAR="${1:0:1}"
  local REMAINDER="${1:1}"
  _n_init $CHAR || return # return if empty
  case "$CHAR" in
    [0-9])
      _n_9 "$REMAINDER"
      ;;
    + | -)
      _n_8 "$REMAINDER"
      ;;
    *)
      return 99
      ;;
  esac
}

_n_6() {
  local CHAR="${1:0:1}"
  local REMAINDER="${1:1}"
  _n_init $CHAR || return # return if empty
  case "$CHAR" in
    [0-9])
      _n_6 "$REMAINDER"
      ;;
    e | E)
      _n_7 "$REMAINDER"
      ;;
    *)
      return 99
      ;;
  esac
}

_n_5() {
  local CHAR="${1:0:1}"
  local REMAINDER="${1:1}"
  _n_init $CHAR || return # return if empty
  case "$CHAR" in
    [0-9])
      _n_6 "$REMAINDER"
      ;;
    *)
      return 99
      ;;
  esac
}

_n_4() {
  local CHAR="${1:0:1}"
  local REMAINDER="${1:1}"
  _n_init $CHAR || return # return if empty
  case "$CHAR" in
    [0-9])
      _n_4 "$REMAINDER"
      ;;
    .)
      _n_5 "$REMAINDER"
      ;;
    e | E)
      _n_7 "$REMAINDER"
      ;;
    *)
      return 99
      ;;
  esac
}

_n_3() {
  local CHAR="${1:0:1}"
  local REMAINDER="${1:1}"
  _n_init $CHAR || return # return if empty
  case "$CHAR" in
    [0-9])
      _n_4 "$REMAINDER"
      ;;
    .)
      _n_5 "$REMAINDER"
      ;;
    e | E)
      _n_7 "$REMAINDER"
      ;;
    *)
      return 99
      ;;
  esac
}


_n_2() {
  local CHAR="${1:0:1}"
  local REMAINDER="${1:1}"
  _n_init $CHAR || return # return if empty
  case "$CHAR" in
    .)
      _n_5 "$REMAINDER"
      ;;
    e | E)
      _n_7 "$REMAINDER"
      ;;
    *)
      return 99
      ;;
  esac
}

_n_1() {
  local CHAR="${1:0:1}"
  local REMAINDER="${1:1}"
  _n_init $CHAR || return # return if empty
  case "$CHAR" in
    0)
      _n_2 "$REMAINDER"
      ;;
    [1-9])
      _n_3 "$REMAINDER"
      ;;
    *)
      return 99
      ;;
  esac
}

_n_0() {
  local CHAR="${1:0:1}"
  local REMAINDER="${1:1}"
  _n_init $CHAR || return # return if empty
  case "$CHAR" in
    -)
      _n_1 "$REMAINDER"
      ;;
    [1-9])
      _n_3 "$REMAINDER"
      ;;
    0)
      _n_2 "$REMAINDER"
      ;;
    *)
      return 99
      ;;
  esac
}

_n_init() {
  [ -z "$1" ] && return 1
  CURRENT_VALUE+="$1"
  GLOBAL_COUNTER=$((GLOBAL_COUNTER + 1))
}