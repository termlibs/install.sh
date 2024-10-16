#!/usr/bin/env bash

# shellcheck source=./utils.sh
source ./tests/utils.sh

# shellcheck source=../scripts/main.sh
source ./scripts/main.sh

# shellcheck source=../../logging.sh/logging.sh
source ../logging.sh/logging.sh

# shellcheck source=../../test.sh/assert.sh
source ../test.sh/assert.sh

tempfiles=()
trap 'rm -f "${tempfiles[@]}"' EXIT
declare -a data keys

printf "Supported apps:\n"
while true; do
  read -r shortname repo source file_pattern archive_path archive_depth
  if [[ ${shortname:0:1} == "-" ]] || [[ $shortname == "shortname" ]]; then
    continue
  fi
  if [ -z "$shortname" ]; then
    break
  fi
  printf "  - %s" "$shortname"
  if [[ $source == github ]]; then
    printf " ( $_GITHUB_API/%s )" "$repo"
  elif
    [[ $source == url ]]
  then
    printf " ( https://%s/%s )" "$repo" "$(dirname "$file_pattern")"
  fi
  printf "\n"
done <<< "$_APP_MD"

# Test _get_info
eval keys="($(_get_info "_keys"))"
for app in yq gh; do
  eval data="($(_get_info "$app"))"
  assert_string_eq "${data[0]}" "$app"
  for i in "${!keys[@]}"; do
    elog -l DEBUG "${keys[$i]}: ${data[$i]}"
  done
done

# Test _is_archive
for good in \
  "file.tar" \
  "file.tar.gz" \
  "file.tgz" \
  "file.zip" \
  "file.tar.xz"; do
  assert_exit_code -c 0 _is_archive "$good"
done

for bad in \
  "file" \
  "file.tar.bz2" \
  "file.tar.xz.gz"; do # bz2 not supported atm
  assert_exit_code -c 1 _is_archive "$bad"
done

app_temp=$(mktemp)
tempfiles+=("$app_temp")
_download_release yq v4.44.3 > "$app_temp"
if is_app "$app_temp"; then
  elog -l INFO -n "${BASH_SOURCE[0]}" "Successfully downloaded yq binary"
else
  elog -l ERROR -n "${BASH_SOURCE[0]}" "Failed to download yq"
  exit 1
fi
