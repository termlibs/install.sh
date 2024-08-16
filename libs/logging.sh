#!/bin/bash

_ansi_red="\e[1;31m"
_ansi_yellow="\e[1;33m"
_ansi_green="\e[1;32m"
_ansi_cyan="\e[1;36m"
_ansi_purple="\e[1;35m"
_ansi_blue="\e[1;34m"
_ansi_reset="\e[0m"
_ansi_bold="\e[1m"

declare -A _LOGLEVEL=([TRACE]=0 [DEBUG]=1 [INFO]=2 [WARN]=3 [ERROR]=4 [FATAL]=5)

elog() {
  local opts level force ws pad_level ll timestamp use_color fn_name
  opts="$(getopt -o l:f --long level:force -n 'assert_string_eq' -- "$@")"
  [ $? -ne 0 ] && return 1
  eval set -- "$opts"
  level="${LOGLEVEL:-INFO}"
  force=false
  while true; do
    case "$1" in
      -l | --level)
        level="$2"
        shift 2
        ;;
      -f | --force)
        force=true
        shift
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
  if [ "$force" = true ]; then
    level="FATAL"
  fi

  ws=$((5 - ${#level}))
  pad_level="$level"
  for ((i = 0; i < ws; i++)); do
    pad_level+=" "
  done
  ll="${LOGLEVEL:-INFO}"

  timestamp="$(date +%H:%M:%S)"
  use_color="$([[ "$TERM" = *"color" ]] && echo true || echo false)"
  if [[ "$use_color" = true ]]; then
    fn_name="${_ansi_bold}${FUNCNAME[1]}${_ansi_reset}"
  else
    fn_name="${FUNCNAME[1]}"
  fi
  case $level in
    TRACE)
      if [[ "${_LOGLEVEL[$level]}" -ge "${_LOGLEVEL[$ll]}" ]]; then
        if [[ "$use_color" = true ]]; then
          level="${_ansi_purple}${pad_level}${_ansi_reset}"
        else
          level="${pad_level}"
        fi
      else
        return 0
      fi
      ;;
    DEBUG)
      if [[ "${_LOGLEVEL[$level]}" -ge "${_LOGLEVEL[$ll]}" ]]; then
        if [[ "$use_color" = true ]]; then
          level="${_ansi_blue}${pad_level}${_ansi_reset}"
        else
          level="${pad_level}"
        fi
      else
        return 0
      fi
      ;;
    INFO)
      if [[ "${_LOGLEVEL[$level]}" -ge "${_LOGLEVEL[$ll]}" ]]; then
        if [[ "$use_color" = true ]]; then
          level="${_ansi_green}${pad_level}${_ansi_reset}"
        else
          level="${pad_level}"
        fi
      else
        return 0
      fi
      ;;
    WARN)
      if [[ "${_LOGLEVEL[$level]}" -ge "${_LOGLEVEL[$ll]}" ]]; then
        if [[ "$use_color" = true ]]; then
          level="${_ansi_yellow}${pad_level}${_ansi_reset}"
        else
          level="${pad_level}"
        fi
      else
        return 0
      fi
      ;;
    ERROR)
      if [[ "${_LOGLEVEL[$level]}" -ge "${_LOGLEVEL[$ll]}" ]]; then
        if [[ "$use_color" = true ]]; then
          level="${_ansi_red}${pad_level}${_ansi_reset}"
        else
          level="${pad_level}"
        fi
      else
        return 0
      fi
      ;;
    FATAL)
      if [[ "${_LOGLEVEL[$level]}" -ge "${_LOGLEVEL[$ll]}" ]]; then
        if [[ "$use_color" = true ]]; then
          level="${_ansi_bold}${_ansi_red}${pad_level}${_ansi_reset}"
        else
          level="${pad_level}"
        fi
      else
        return 0
      fi
      ;;
  esac
  printf "%s [%b] %b: %s\n" "$timestamp" "$level" "$fn_name" "$1"
}
