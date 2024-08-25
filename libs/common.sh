#!/usr/bin/env bash

# zsh handling
if  [ -n "$ZSH_VERSION" ]; then
  emulate -L bash
fi

# `_validate_file`
# ----------------
# Run various validations with the given path, intended to be used with
# a command line argument/option for common checks with nice output.
# ```
# Usage: _validate_file <path> [flags]
# Returns: None
# Exit codes:
#  0: No checks failed
#  1: No input file (-z)
# 10: File does not exist (-e)
# 11: File is not readable (-r)
# 12: File is not a regular file (-f)
# 13: File is empty (-s)
# 14: File is not writable (-w)
# 15: File is not executable (-x)
# ```
_validate_path() {
  [ -z "$1" ] && return 1

  local file="$1"
  local flags="${2:-er}"
  while true; do
    local flag="${flags:0:1}"
    flags="${flags:1}"
    case "$flag" in
      e)
        [ -e "$file" ] || {
          printf "File does not exist: %s\n" "$file"
          return 10
        }
        ;;
      r)
        [ -r "$file" ] || {
          printf "File is not readable: %s\n" "$file"
          return 11
        }
        ;;
      f)
        [ -f "$file" ] || {
          printf "File is not a regular file: %s\n" "$file"
          return 12
        }
        ;;
      d)
        [ -d "$file" ] || {
          printf "File is not a directory: %s\n" "$file"
          return 12
        }
        ;;
      s)
        [ -s "$file" ] || {
          printf "File is empty: %s\n" "$file"
          return 13
        }
        ;;
      w)
        [ -w "$file" ] || {
          printf "File is not writable: %s\n" "$file"
          return 14
        }
        ;;
      x)
        [ -x "$file" ] || {
          printf "File is not executable: %s\n" "$file"
          return 15
        }
        ;;

      *)
        break
        ;;
    esac
  done
}