#!/usr/bin/env bash
# shellcheck disable=SC3043,SC2001
# sourced from https://github.com/cloudflare/semver_bash/blob/master/semver.sh
# then linted with shellcheck and tweaked for preferences
#!/usr/bin/env sh

red='\033[0;31m'
nc='\033[0m' # No Color

semver_parse() {
  local RE M m p s result
  if [ -z "$1" ]; then
    echo "No version provided" >&2
    return 1
  fi
  RE="v?(0|[1-9][0-9]*)\\.?(0?|[1-9][0-9]*)\\.?(0?|[1-9][0-9]*)(?:-((?:0|[1-9][0-9]*|[0-9]*[a-zA-Z-][0-9a-zA-Z-]*)(?:\\.(?:0|[1-9][0-9]*|[0-9]*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\\+([0-9a-zA-Z-]+(?:\\.[0-9a-zA-Z-]+)*))?\$"
  #MAJOR #MINOR #PATCH $SPECIAL
  read -r M m p s <<< "$(printf "%s" "$1" | perl -pe "s#$RE#\1 \2 \3 \4#")"
  result="$(printf "%d %d %d %s" "$M" "$m" "$p" "$s" 2> /dev/null)"
  # shellcheck disable=SC2181
  if [ $? -ne 0 ]; then
    echo "Invalid version provided" >&2
    return 1
  fi
  echo "$result"
}

# shellcheck disable=SC2317
semver_eq() {
  local MAJOR_A MINOR_A PATCH_A SPECIAL_A MAJOR_B MINOR_B PATCH_B SPECIAL_B
  read -r MAJOR_A MINOR_A PATCH_A SPECIAL_A <<< "$(parse_semver "$1")"
  read -r MAJOR_B MINOR_B PATCH_B SPECIAL_B <<< "$(parse_semver "$2")"
  if [ "$MAJOR_A" -ne "$MAJOR_B" ] || [ "$MINOR_A" -ne "$MINOR_B" ] || [ "$PATCH_A" -ne "$PATCH_B" ] || [ "_$SPECIAL_A" != "_$SPECIAL_B" ]; then
    return 1
  fi
  return 0
}

# shellcheck disable=SC2317
semver_lt() {
  local MAJOR_A MINOR_A PATCH_A SPECIAL_A MAJOR_B MINOR_B PATCH_B SPECIAL_B

  read -r MAJOR_A MINOR_A PATCH_A SPECIAL_A <<< "$(parse_semver "$1")"
  read -r MAJOR_B MINOR_B PATCH_B SPECIAL_B <<< "$(parse_semver "$2")"

  if [ "$MAJOR_A" -lt "$MAJOR_B" ]; then return 0; fi
  if [ "$MAJOR_A" -eq "$MAJOR_B" ] && [ "$MINOR_A" -lt "$MINOR_B" ]; then return 0; fi
  if [ "$MAJOR_A" -eq "$MAJOR_B" ] && [ "$MINOR_A" -eq "$MINOR_B" ] && [ "$PATCH_A" -lt "$PATCH_B" ]; then return 0; fi
  if [ -z "$SPECIAL_A" ] && [ -n "$SPECIAL_B" ]; then return 1; fi
  if [ -n "$SPECIAL_A" ] && [ -z "$SPECIAL_B" ]; then return 0; fi
  if [ -n "$SPECIAL_A" ] && [ -n "$SPECIAL_B" ] && [ "$SPECIAL_A" \< "$SPECIAL_B" ]; then return 0; fi

  return 1
}

semver_validate() {
  local M m p s CHK
  M=0
  m=0
  p=0
  s=0
  CHK=0

  read -r M m p s <<< "$(semver_parse "$1")"
  if [ "X${M}X" = "XX" ]; then return 1; fi
  local RE="^([0-9]*)$"
  CHK=$(echo "${M}" | sed -r "s/${RE}/\1/g")
  if ! [ "${CHK}" -ge 0 ] && [ "${CHK}" -le 99999999 ] 2> /dev/null; then return 1; fi
  CHK=$(echo "${m}" | sed -r "s/${RE}/\1/g")
  if ! [ "${CHK}" -ge 0 ] && [ "${CHK}" -le 99999999 ] 2> /dev/null; then return 1; fi
  CHK=$(echo "${p}" | sed -r "s/${RE}/\1/g")
  if ! [ "${CHK}" -ge 0 ] && [ "${CHK}" -le 99999999 ] 2> /dev/null; then return 1; fi

  return 0
}

semver_new() {
  if [ "$4" = "" ]; then
    printf "%d.%d.%d" "${1:-0}" "${2:-0}" "${3:-0}"
  else
    printf "%d.%d.%d-%s" "${1:-0}" "${2:-0}" "${3:-0}" "$4"
  fi
}

semver_cmp() {
  local MAJOR_A MINOR_A PATCH_A SPECIAL_A MAJOR_B MINOR_B PATCH_B SPECIAL_B
  read -r MAJOR_A MINOR_A PATCH_A SPECIAL_A <<< "$(semver_parse "$1")"
  read -r MAJOR_B MINOR_B PATCH_B SPECIAL_B <<< "$(semver_parse "$2")"

  if [ "X${MAJOR_A}X" = "XX" ]; then echo "${red}WARN${nc} :: '$1' is not a valid semver"; fi
  if [ "X${MAJOR_B}X" = "XX" ]; then echo "${red}WARN${nc} :: '$2' is not a valid semver"; fi

  # major
  if [ "$MAJOR_A" -lt "$MAJOR_B" ]; then return 2; fi
  if [ "$MAJOR_A" -gt "$MAJOR_B" ]; then return 1; fi

  # minor
  if [ "$MINOR_A" -lt "$MINOR_B" ]; then return 2; fi
  if [ "$MINOR_A" -gt "$MINOR_B" ]; then return 1; fi

  # patch
  if [ "$PATCH_A" -lt "$PATCH_B" ]; then return 2; fi
  if [ "$PATCH_A" -gt "$PATCH_B" ]; then return 1; fi

  # special
  if [ "$SPECIAL_A" = "" ] && [ "$SPECIAL_B" != "" ]; then
    #        echo "C 1  ||  \$SPECIAL_A = $SPECIAL_A, \$SPECIAL_B = $SPECIAL_B";
    return 1 # missing is more than having
  fi

  if [ "$SPECIAL_A" != "" ] && [ "$SPECIAL_B" = "" ]; then
    return 2 # having is less than missing
  fi
  if [ "$(expr "$SPECIAL_A" \< "$SPECIAL_B")" -eq 1 ]; then return 2; fi
  if [ "$(expr "$SPECIAL_A" \> "$SPECIAL_B")" -eq 1 ]; then return 1; fi

  # equal
  return 0
}

semver_eq() {
  semver_cmp "$1" "$2"
  local RESULT=$?

  if [ "$RESULT" -ne 0 ]; then
    # not equal
    return 1
  fi

  return 0
}

semver_lt() {
  semver_cmp "$1" "$2"
  local RESULT=$?

  if [ "$RESULT" -ne 2 ]; then
    # not lesser than
    return 1
  fi

  return 0
}

semver_gt() {
  semver_cmp "$1" "$2"
  local RESULT=$?

  if [ "$RESULT" -ne 1 ]; then
    # not greater than
    return 1
  fi

  return 0
}

semver_le() {
  semver_gt "$1" "$2"
  local RESULT=$?

  if [ "$RESULT" -ne 1 ]; then
    # not lesser than or equal
    return 1
  fi

  return 0
}

semver_ge() {
  semver_lt "$1" "$2"
  local RESULT=$?

  if [ "$RESULT" -ne 1 ]; then
    # not greater than or equal
    return 1
  fi

  return 0
}

semver_bump_to() {
  local M m p s
  read -r M m p s <<< "$(semver_parse "$1")"
  case "$2" in
    major)
      M=$((M + 1))
      m=0
      p=0
      s=""
      ;;
    minor)
      m=$((m + 1))
      p=0
      s=""
      ;;
    patch)
      p=$((p + 1))
      s=""
      ;;
    *)
      printf "Cannot bump to %s\n" "$2" >&2
      return 1
      ;;
  esac

  semver_new "$M" "$m" "$p" "$s"
}


semver_strip_to() {
  local M m p s
  read -r M m p s <<< "$(semver_parse "$1")"
  case "$2" in
    major) printf "%s" "$M" ;;
    minor) printf "%s.%s" "$M" "$m" ;;
    patch) printf "%s.%s.%s" "$M" "$m" "$p" ;;
    *)
      printf "Cannot strip to %s\n" "$2" >&s
      return 1
      ;;
  esac
}

if [ "___semver.sh" = "___$(basename "$0")" ]; then
  if [ "$2" = "" ]; then
    echo "$0 <version> <command> [version]"
    echo "Commands: cmp, eq, lt, gt, bump_major, bump_minor, bump_patch, strip_special"
    echo ""
    echo "cmp: compares left version against right version, return 0 if equal, 2 if left is lower than right, 1 if left is higher than right"
    echo "eq: compares left version against right version, returns 0 if both versions are equal"
    echo "lt: compares left version against right version, returns 0 if left version is less than right version"
    echo "gt: compares left version against right version, returns 0 if left version is greater than than right version"
    echo ""
    echo "bump_to: bump to major|minor|patch"
    echo ""
    echo "strip_to: strip to major|minor|patch"
    exit 3
  fi

  if [ "$2" = "cmp" ]; then
    semver_cmp "$1" "$3"
    RESULT=$?
    echo $RESULT
    exit $RESULT
  fi

  if [ "$2" = "eq" ]; then
    semver_eq "$1" "$3"
    RESULT=$?
    echo $RESULT
    exit $RESULT
  fi

  if [ "$2" = "lt" ]; then
    semver_lt "$1" "$3"
    RESULT=$?
    echo $RESULT
    exit $RESULT
  fi

  if [ "$2" = "gt" ]; then
    semver_gt "$1" "$3"
    RESULT=$?
    echo $RESULT
    exit $RESULT
  fi

  if [ "$2" = "le" ]; then
    semver_le "$1" "$3"
    RESULT=$?
    echo $RESULT
    exit $RESULT
  fi

  if [ "$2" = "ge" ]; then
    semver_ge "$1" "$3"
    RESULT=$?
    echo $RESULT
    exit $RESULT
  fi

  if [ "$2" = "bump_to" ]; then
    semver_bump_to "$1" "$3" || exit 1
    exit 0
  fi

  if [ "$2" = "strip_to" ]; then
    semver_strip_to "$1" "$3" || exit 1
    exit 0
  fi

  if [ "$2" = "parse" ]; then
    VER=$1
    shift
    shift

    MA=0
    MI=0
    PA=0
    SP=""
    semver_parse "$VER" MA MI PA SP
    eval echo "export \$1=$MA\;"
    eval echo "export \$2=$MI\;"
    eval echo "export \$3=$PA\;"
    eval echo "export \$4=$SP\;"
    echo ""
    exit 0
  fi
fi
