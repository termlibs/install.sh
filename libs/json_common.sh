#!/usr/bin/env bash
_SCRIPT_SH_VERSION=0.0.1

# source grammar from https://ecma-international.org/publications-and-standards/standards/ecma-404/
_ERROR_SYNTAX() {
  printf "SYNTAX ERROR: Unexpected character at position %d: '%s'\n" "$1" "$2" >&2
  return 99
}

_GET_REPO_FILE() {
  local _source maybe_folder maybe_url script_file filename directory
  filename="${1}"
  directory="${2:-libs}"
  script_file="$(realpath "${BASH_SOURCE[0]}")"
  maybe_folder="$(dirname "$script_file")"
  maybe_url="https://raw.githubusercontent.com/adam-huganir/scripts.sh/v${_SCRIPT_SH_VERSION}/$directory/$1"
  if [ -f "$maybe_folder/$filename" ]; then
    _source="$(cat "$maybe_folder/$filename")"
  elif [ -f "$filename" ]; then
    _source="$(cat "$filename")"
  elif curl -sSLf --head "$maybe_url" > /dev/null 2>&1; then
    _source="$(curl -sSLf "$maybe_url" 2> /dev/null)"
  else
    printf "error: unable to find file '%s'\n" "$filename" >&2
    return 1
  fi
}
