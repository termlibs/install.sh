#!/usr/bin/env bash
_SCRIPT_SH_VERSION=0.0.1

# source grammar from https://ecma-international.org/publications-and-standards/standards/ecma-404/
# start ──┬───► object ────┬─► end
#         ├───► array ──►──┤
#         ├───► number ─►──┤
#         ├───► string ─►──┤
#         ├───► true  ──►──┤
#         ├───► false ──►──┤
#         ╰───► null  ──►──╯

parse_json() {
  #  set -x
  local current_path="$1"
  local TRIMMED="$(slurp_whitespace "$2")"
  local CHAR="${TRIMMED:0:1}"
  local RAW_INPUT="$TRIMMED"
  local value=""
  local save_value="false"
  case "$CHAR" in
    '"')
      eval R="$(_string "$RAW_INPUT")" || return "$?"
      value=${R[0]}
      next=${R[1]}
      save_value="true"
      ;;
    [[:digit:]] | '-')
     eval R="$(_number "$RAW_INPUT")" || return "$?"
      value=${R[0]}
      next=${R[1]}
      save_value="true"
      ;;
    "t")
     eval R="$(_true "$RAW_INPUT")" || return "$?"
      value=${R[0]}
      next=${R[1]}
      save_value="true"
      ;;
    "f")
     eval R="$(_false "$RAW_INPUT")" || return "$?"
      value=${R[0]}
      next=${R[1]}
      save_value="true"
      ;;
    "n")
     eval R="$(_null "$RAW_INPUT")" || return "$?"
      value=${R[0]}
      next=${R[1]}
      ;;
    '{')
     eval R="$(_object "$current_path" "$RAW_INPUT")" || return "$?"
      value=${R[0]}
      next=${R[1]}
      ;;
    '[')
     eval R="$(_array "$current_path" "$RAW_INPUT")" || return "$?"
      value=${R[0]}
      next=${R[1]}
      ;;
    *)
      _ERROR_SYNTAX "$GLOBAL_COUNTER" "$FIRST_CHAR" >&2
      return 99
      ;;
  esac
  if [ "$save_value" = "true" ]; then
    save_data "$current_path" "$value"
  fi
  printf '( %s %s )' "${value@Q}" "${next@Q}"
}
