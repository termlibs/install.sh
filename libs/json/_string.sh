#!/usr/bin/env bash

# source grammar from https://ecma-international.org/publications-and-standards/standards/ecma-404/
source ./libs/json/_util.sh

# string has 5 states, start, escape start, escape end, end, and anything else in the middle
# ss for string state
_ss() {
  local TOKEN CHAR IDX ESCAPING
  TOKEN="$1"
  IDX=0
  CHAR="${TOKEN:$IDX:1}"

  # start state check (idiot check)
  [ "$CHAR" = '"' ] || return 99

  ESCAPING=false
  IDX=$((IDX + 1))
  while [ $IDX -lt ${#TOKEN} ]; do
    CHAR="${TOKEN:$IDX:1}"
    case "$CHAR" in
      \")
        if [ "$IDX" -ne $((${#TOKEN} - 1)) ]; then
          return 99
        fi
        _ss_end "$CHAR" "$IDX" || return 99
        ;;
      \\)
        IDX=$((IDX + 1))
        CHAR="${TOKEN:$IDX:1}"
        _ss_escape "$CHAR" "$IDX" || return 99
        ;;
      *)
        _ss_middle "$TOKEN" "$IDX" || return 99
        ;;
    esac
    IDX=$((IDX + 1))
  done
}

_ss_escape() {
  local CHAR IDX
  CHAR="$1"
  IDX="$2"
  case "$CHAR" in
    \" | \\ | / | b | f | n | r | t | u)
      # valid  escape characters
      return
      ;;
    *)
      return 99
      ;;
  esac
}

_ss_middle() {
  local TOKEN IDX CHAR
  TOKEN="$1"
  IDX="$2"
  CHAR="${TOKEN:$IDX:1}"
  case "$CHAR" in
    \")
      return 99
      ;;
    *)
      return
      ;;
  esac

}

_ss_end() {
  local TOKEN CHAR IDX
  TOKEN="$1"
  IDX="$2"
  CHAR="${TOKEN:$IDX:1}"
  [ "$CHAR" = '"' ] || return 99 # idiot check
  printf "String end\n" >&2
}
