#!/usr/bin/env bash

# shellcheck source=../libs/assert.sh
source ./libs/assert.sh

# shellcheck source=../scripts/install_all.sh
source ./scripts/install_all.sh

declare -a data keys
declare shortname repo source file_pattern archive_path archive_depth

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
  if [[ "$source" == github ]]; then
    printf " ( $_GITHUB/%s )" "$repo"
  elif
    [[ "$source" == url ]]; then
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
  "file.tar.xz.gz"; do
  assert_exit_code -c 1 _is_archive "$bad"
done
