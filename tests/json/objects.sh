#!/usr/bin/env bash

# shellcheck source=../../libs/json/main.sh
source ./libs/json/main.sh

# shellcheck source=../../libs/logging.sh
source ./libs/logging.sh

# shellcheck source=../../libs/assert.sh
source ./libs/assert.sh

test_string='
{"this": "is", "a": "test"}
'
echo "$test_string"
parse_json "" "$test_string"
echo cat "$__DATAFILE__"
