#!/usr/bin/env bash
_SCRIPT_SH_VERSION=0.0.1
# source grammar from https://ecma-international.org/publications-and-standards/standards/ecma-404/
#_GET_REPO_FILE() { local _source maybe_folder maybe_url script_file filename directory;filename="${1}";directory="${2:-libs}";script_file="$(realpath "${BASH_SOURCE[0]}")";maybe_folder="$(dirname "$script_file")";maybe_url="https://raw.githubusercontent.com/adam-huganir/scripts.sh/v${_SCRIPT_SH_VERSION}/$directory/$1";if [ -f "$maybe_folder/$filename" ]; then;_source="$(cat "$maybe_folder/$filename")";elif [ -f "$filename" ]; then;_source="$(cat "$filename")";elif curl -sSLf --head "$maybe_url" > /dev/null 2>&1; then;_source="$(curl -sSLf "$maybe_url" 2> /dev/null)";else printf "error: unable to find file '%s'; " "$filename" >&2;return 1;fi; };;
#eval "$(_GET_REPO_FILE json_common.sh)"
eval "$(cat ./libs/json_common.sh)"

GLOBAL_COUNTER=0
CURRENT_KEY=""
CURRENT_VALUE=""
KEY_DIVIDER=":"

_ERROR_SYNTAX() {
  printf "SYNTAX ERROR: Unexpected character at position %d: '%s'\n" "$1" "$2" >&2
  return 99
}

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

_parse_token() {
  # no validation, just guessing based on first letter
  local TOKEN FIRST_CHAR
  TOKEN="$1"
  if [ -z "$TOKEN" ]; then
    TOKEN="$(cat -)"
  fi
  FIRST_CHAR="${TOKEN:0:1}"
  case "$FIRST_CHAR" in
    '"')
      printf "string"
      _parse_string "${TOKEN}" || return 99
      ;;
    [[:digit:]] | '-')
      printf "number"
      ;;
    "t")
      printf "true"
      ;;
    "f")
      printf "false"
      ;;
    "n")
      _parse_null "${TOKEN}" || return 99
      ;;
    '{')
      printf "object"
      ;;
    '[')
      printf "array"
      ;;
    *)
      _ERROR_SYNTAX "$GLOBAL_COUNTER" "$FIRST_CHAR" >&2
      return 99
      ;;
  esac
}

_parse_null() {
  if [ "$1" != "null" ]; then
    case "$1" in
      nul*)
        GLOBAL_COUNTER=$(($GLOBAL_COUNTER + 3))
        ;;
      nu*)
        GLOBAL_COUNTER=$(($GLOBAL_COUNTER + 2))
        ;;
    esac
    printf "Unexpected character at position %d: '%s'\n" "$GLOBAL_COUNTER" "$1" >&2
    return 99
  fi
}

_parse_string() {
  # coming in, we only know that the first character is a double quote
  return
}

_tknz_STRING() {
  local STRING IDX CHAR ESCAPING
  STRING="$1"
  IDX=0
  ESCAPING=0
  while [ $IDX -lt ${#STRING} ]; do
    CHAR="${STRING:$IDX:1}"
    case "$CHAR" in
      '"')
        if [ $IDX -eq 0 ]; then
          printf "String start\n" >&2
        elif [ "$IDX" -ne "${#STRING}" ]; then
          printf "Invalid character in string at position %d: '%s'\n" "$IDX" "$CHAR" >&2
          return 99
        else
          printf "String end\n" >&2
        fi
        printf "Completed string\n" >&2
        return 100
        ;;
      "\\")
        printf "Escape character start: \\" >&2
        ESCAPING=1
        ;;
      *)
        if [ $ESCAPING] -eq 0 ]; then
          printf "Character: %s\n" "$CHAR" >&2
        else
          case "$CHAR" in
            '"')
              printf "Escaped character: %s\n" "\\$CHAR" >&2
              ;;
            "\\")
              printf "Escaped character: %s\n" "\\$CHAR" >&2
              ;;
            "/")
              printf "Escaped character: %s\n" "\\$CHAR" >&2
              ;;
            "b")
              printf "Escaped character: %s\n" "\\$CHAR" >&2
              ;;
            "f")
              printf "Escaped character: %s\n" "\\$CHAR" >&2
              ;;
            "n")
              printf "Escaped character: %s\n" "\\$CHAR" >&2
              ;;
            "r")
              printf "Escaped character: %s\n" "$CHAR" >&2
              ;;
            "t")
              printf "Escaped character: %s\n" "$CHAR" >&2
              ;;
            "u")
              printf "Unicode escape start\n" >&2
              ;;
            *)
              printf "Invalid escape character: '%s'\n" "$CHAR" >&2
              return 99
              ;;
          esac
          ESCAPING=0
        fi
        ;;
    esac
    IDX=$((IDX + 1))
  done
  prinitf "%s" "$1"
}

#declare -a _data
#
#txt="$(mktemp)"
##printf "Using temp file: %s\n" "$txt"
#trap "rm -f $txt" RETURN
#

#cat > /dev/null << OLD
#
#_tknz_NUMBER() {
#  printf "%s" "$1"
#}
#
#_tknz_BOOL() {
#  case "$1" in
#    true) printf "0" ;;
#    false) printf "1" ;;
#    *)
#      printf "Unexpected bool: '%s'\n" "$1" >&2
#      return 99
#      ;;
#  esac
#}
#
#_tknz_NULL() {
#  if ! [ "$1" = "null" ]; then
#    printf "Unexpected null: '%s'\n" "$1" >&2
#    return 99
#  fi
#  printf "null"
#}
#
#_read_TOKEN() {
#  local TOKEN INPUT
#  INPUT="$1"
#  if [ -z "$INPUT" ]; then
#    INPUT="$(cat -)"
#  fi
#  WORD_LENGTH="${#INPUT}"
#  TOKEN_INDEX=0
#  while IFS='' read -r -n 1 TOKEN; do
#    case "$TOKEN_INDEX" in
#      0)
#        case "$TOKEN" in
#          "{")
#            printf "Object start\n"
#            IFS='' read -r ANOTHER
#            printf "Object key: %s\nEnd object key\n" "$ANOTHER"
#            ;;
#          '"')
#            printf "String start\n"
#            ;;
#          [[:digit:]])
#            printf "Number start\n"
#            ;;
#          "t" | "f")
#            printf "Bool start\n"
#            ;;
#          "n")
#            printf "Null start\n"
#            ;;
#          *)
#            printf "Unexpected start: '%s'\n" "$TOKEN" >&2
#            return 99
#            ;;
#        esac
#        ;;
#      "${WORD_LENGTH}")
#        printf "%s --- done\n" "$TOKEN"
#        ;;
#      *)
#        printf "%s" "$TOKEN"
#        ;;
#    esac
#    TOKEN_INDEX=$((TOKEN_INDEX + 1))
#  done <<< "$INPUT"
#}
#OLD
