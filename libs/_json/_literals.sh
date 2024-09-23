_null() {
  [ "$1" = "null" ] || return 99
  GLOBAL_COUNTER=$((GLOBAL_COUNTER + 4))
  printf "null"
}

_true() {
  [ "$1" = "true" ] || return 99
  GLOBAL_COUNTER=$((GLOBAL_COUNTER + 4))
  printf "true"
}

_false() {
  [ "$1" = "false" ] || return 99
  GLOBAL_COUNTER=$((GLOBAL_COUNTER + 5))
  printf "false"
}
