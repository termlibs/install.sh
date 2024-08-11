#!/usr/bin/env bash
export GLOBAL_COUNTER=0
export CURRENT_VALUE=""

source libs/json/_number.sh

for n in \
   1.2 \
   2   \
  -2.2 \
  -2   \
  1e4  \
  0.1e4 \
  0e4  \
  -1.44E-3 \
  ; do
  CURRENT_VALUE=""
#  set -x
  _n_0 "$n"
  if [ "$CURRENT_VALUE" = "$n" ]; then
    printf "   %4s == %4s\n" "$CURRENT_VALUE" "$n"
  else
    printf "!! %4s != %4s\n" "$CURRENT_VALUE" "$n"
  fi
done

