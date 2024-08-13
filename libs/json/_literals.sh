_null() {
  [ "$1" = "null" ] || return 99
  printf "null"
}

_true() {
  [ "$1" = "true" ] || return 99
  printf "true"
}

_false() {
  [ "$1" = "false" ] || return 99
  printf "false"
}
