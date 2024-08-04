#!/usr/bin/env bash

# source grammar from https://ecma-international.org/publications-and-standards/standards/ecma-404/

GLOBAL_COUNTER=0

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
      printf "null"
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
  if [ "$1" = "null" ]; then
    printf "null"
  else
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

declare -a _data

txt="$(mktemp)"
#printf "Using temp file: %s\n" "$txt"
trap "rm -f $txt" RETURN

set +x
_T="{ \"1\": 2 }"
printf "%s is an %s\n" "$_T" "$(_parse_token "$_T")"
_T="\"{ \\\"1\\\": 2 }\""
printf "%s is an %s\n" "$_T" "$(_parse_token "$_T")"
_T="1.2"
printf "%s is an %s\n" "$_T" "$(_parse_token "$_T")"
_T="2"
printf "%s is an %s\n" "$_T" "$(_parse_token "$_T")"
_T="[ \"1\", 2 ]"
printf "%s is an %s\n" "$_T" "$(_parse_token "$_T")"

_T="[ \"1\", 2 "
printf "%s is an %s\n" "$_T" "$(_parse_token "$_T")"
_T="null"
printf "%s is an %s\n" "$_T" "$(_parse_token "$_T")"
_T="nult"
printf "%s is an %s\n" "$_T" "$(_parse_token "$_T")"

cat > /dev/null << OLD

_tknz_NUMBER() {
  printf "%s" "$1"
}

_tknz_BOOL() {
  case "$1" in
    true) printf "0" ;;
    false) printf "1" ;;
    *)
      printf "Unexpected bool: '%s'\n" "$1" >&2
      return 99
      ;;
  esac
}

_tknz_NULL() {
  if ! [ "$1" = "null" ]; then
    printf "Unexpected null: '%s'\n" "$1" >&2
    return 99
  fi
  printf "null"
}

_read_TOKEN() {
  local TOKEN INPUT
  INPUT="$1"
  if [ -z "$INPUT" ]; then
    INPUT="$(cat -)"
  fi
  WORD_LENGTH="${#INPUT}"
  TOKEN_INDEX=0
  while IFS='' read -r -n 1 TOKEN; do
    case "$TOKEN_INDEX" in
      0)
        case "$TOKEN" in
          "{")
            printf "Object start\n"
            IFS='' read -r ANOTHER
            printf "Object key: %s\nEnd object key\n" "$ANOTHER"
            ;;
          '"')
            printf "String start\n"
            ;;
          [[:digit:]])
            printf "Number start\n"
            ;;
          "t" | "f")
            printf "Bool start\n"
            ;;
          "n")
            printf "Null start\n"
            ;;
          *)
            printf "Unexpected start: '%s'\n" "$TOKEN" >&2
            return 99
            ;;
        esac
        ;;
      "${WORD_LENGTH}")
        printf "%s --- done\n" "$TOKEN"
        ;;
      *)
        printf "%s" "$TOKEN"
        ;;
    esac
    TOKEN_INDEX=$((TOKEN_INDEX + 1))
  done <<< "$INPUT"
}
OLD
