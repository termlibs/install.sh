#!/usr/bin/env bash

# shellcheck source=../../libs/json/_string.sh
source ./libs/json/_string.sh

# shellcheck source=../../libs/logging.sh
source ./libs/logging.sh

# shellcheck source=../../libs/assert.sh
source ./libs/assert.sh

for s in \
  '"this is a string!"' \
  '"this is a string with a \"quote\""' \
  '"\t\thello!\n\n"' \
  '"\u0000 \uFFFf or something"'; do
  _s="${s:1:-1}"
  _s="${_s//\\\\/\\}"
  assert_string_eq "$(_string "$s")" "$_s"
done

for s in \
  '" this is \z bad escape sequence"' \
  '"\uF3MN is not unicode"' \
  '"This is a string that doesnt terminate' \
  '4'; do
  assert_error --code 99 _string "$s"
done
