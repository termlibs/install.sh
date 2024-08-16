#!/usr/bin/env bash
export GLOBAL_COUNTER=0
export CURRENT_VALUE=""

# shellcheck source=../../libs/json/_number.sh
source ./libs/json/_number.sh

# shellcheck source=../../libs/logging.sh
source ./libs/logging.sh

# shellcheck source=../../libs/assert.sh
source ./libs/assert.sh

for n in \
   "1.2" \
   "2" \
  "-2.2" \
  "-2" \
  "1e4" \
  "0.1e4" \
  "0E4" \
  "-1.44E-3"; do
  assert_string_eq "$(_number "$n")" "$n"
done

for invalid in \
  "1.2.3" \
  "1e" \
  "1e+" \
  "1f3" \
  "-01"; do
  assert_error --code 99 _number -- "$invalid"
done
