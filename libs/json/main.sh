#!/usr/bin/env bash
_SCRIPT_SH_VERSION=0.0.1
# source grammar from https://ecma-international.org/publications-and-standards/standards/ecma-404/
source ./libs/json/_util.sh
source ./libs/json/_string.sh
source ./libs/json/_number.sh
source ./libs/json/_bool.sh
source ./libs/json/_null.sh
source ./libs/json/_object.sh
source ./libs/json/_array.sh

GLOBAL_COUNTER=0
CURRENT_KEY=""
CURRENT_VALUE=""
KEY_DIVIDER=":"

declare -a _data


_ERROR_SYNTAX() {
  printf "SYNTAX ERROR: Unexpected character at position %d: '%s'\n" "$1" "$2" >&2
  return 99
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
