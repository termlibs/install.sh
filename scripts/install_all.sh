#!/usr/bin/env bash

# shellcheck disable=SC2155 #_TEMPDIR if we need it, only create if we don't have it
_TEMPDIR="$(mktemp -dut install-all-XXXXXX)"
with-tempdir() {
  if ! [ -d "$_TEMPDIR" ]; then
    mkdir "$_TEMPDIR" || exit 99 # if we need the temp and can't use it then we should exit
    trap 'rm -rf $_TEMPDIR' EXIT
  fi
  "$@"
}

# for logging purposes, try to output what is actually being called
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  THIS="${0}"
else
  THIS=""
fi

# ERROR CODES
_E_GENERIC_ERROR=1
_E_CLI_PARSE_ERROR=11

_GITHUB="https://api.github.com"
# NOTES: jsonnet has more than one binary
read -d '' -r _APP_MD << MD
| shortname | repo              | source | file_pattern                           | archive_path                | archive_depth |
|-----------|-------------------|--------|----------------------------------------|-----------------------------|---------------|
| yq        | mikefarah/yq      | github | yq_linux_amd64                         | yq                          | -1            |
| gh        | cli/cli           | github | gh_VERSION_linux_amd64.tar.gz          | gh_*_linux_amd64/bin/gh     | 2             |
| helm      | get.helm.sh       | url    | helm-vVERSION-linux-amd64.tar.gz       | linux-amd64/helm            | 1             |
| jsonnet   | google/go-jsonnet | github | go-jsonnet_VERSION_Linux_x86_64.tar.gz | jsonnet                     | 0             |
MD

_create_venv() {
  :
}

_get_info() {
  local app shortname repo source file_pattern archive_path archive_depth
  app=$1
  while true; do
    IFS= read -r line
    if [ -z "$line" ]; then
      break
    fi
    read -r shortname repo source file_pattern archive_path archive_depth <<< "$line"
    if [ "$shortname" = "$app" ]; then
      printf "%s %s %s %s %s %s\n" "$shortname" "$repo" "$source" "$file_pattern" "$archive_path" "$archive_depth"
      return 0
    fi
  done <<< "$_APP_MD"
  printf "error: unable to find info for app '%s'\n" "$app" >&2
  return 1
}

_is_archive() {
  local path
  path="${1}"
  case "$path" in
    *.tar | *.tar.gz | *.tgz | *.zip)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

_extract_if_archive() {
  local path
  path="${1}"
  archive_path="${2}"
  archive_depth="${3}"
  if [ "$path" = "-" ]; then
    data=$(cat -)
  else
    data=$(< "$path")
  fi
  case "$path" in
    *.tar)
      tar --strip-components="$archive_depth" -xf - -C "$archive_path" <<< "$data"
      ;;
    *.tar.gz | *.tgz)
      tar --strip-components="$archive_depth" -xzf - -C "$archive_path" <<< "$data"
      ;;
    *.zip)
      unzip -d "$archive_path" - <<< "$data" #  todo components i forget the syntax offhand
      ;;
    *)
      return 1
      ;;
  esac
}

# INTERNAL
_urlget() {
  if command -v curl &> /dev/null; then
    curl -fsSLo - "$1" 2> /dev/null
  elif command -v wget &> /dev/null; then
    wget -qO- "$1" 2> /dev/null
  else
    echo "error: neither curl nor wget found, unable to access the web" >&2
    return 1
  fi
}

_link_from_release_by_pattern() {
  cat - | yq ".assets[] | select(.name | test(\"$1\")) | .browser_download_url"
}

# we have our own special function here since we use it in the other install functions
_install-yq() {
  if ! command -v yq &> /dev/null || [ "$force" = "true" ]; then
    # install to temp since the user hasn't explicitly asked to install this
    with-tempdir mkdir -p "$_TEMPDIR/bin"
    _urlget "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64" > "$_TEMPDIR/bin/yq"
    chmod +x "$_TEMPDIR/bin/yq"
    export PATH="$_TEMPDIR/bin:$PATH" # add to the path for the duration of the run
  fi
}

_get_gh_release() {
  local repo version asset_match_pattern vversion
  repo=$1
  asset_match_pattern=$2
  version=$3
  if [ -z "$version" ]; then
    version="latest"
  fi
  if [ "$version" = "latest" ]; then
    asset_match_pattern="${asset_match_pattern/VERSION/.*}"
    _urlget "$_GITHUB/repos/$repo/releases/latest" | _link_from_release_by_pattern "$asset_match_pattern"
  else
    vversion="v${version#v}"
    asset_match_pattern="${asset_match_pattern/VERSION/${version}}"
    _urlget "$_GITHUB/repos/$repo/releases/tags/$vversion" | _link_from_release_by_pattern "$asset_match_pattern"
  fi
}

_download_release() {
  local app version download_url
  app=$1
  version=$2
  read -r shortname repo source file_pattern archive_path archive_depth <<< "$(_get_info "$app")"
  case "$source" in
    "github")
      download_url="$(_get_gh_release "$repo" "$file_pattern" "$version")"
      ;;
    "url")
      # TODO: helm special_case_goes_here  for grabbing version
      download_url="https://${repo}/${file_pattern/VERSION/$version}"
      ;;
    *)
      echo "error: unknown source type $source" >&2
      return 1
      ;;
  esac
  _urlget "$download_url"
}

install-github() {
  local repo version asset_match_pattern

}

install-yq() {
  set -x
  # app spec
  local opts PREFIX VERSION force
  opts="$(getopt -o "fv:p:" --long "force,version:,prefix:" -n "${FUNCNAME[0]}" -- "$@")"
  # shellcheck disable=SC2181
  if [ $? -ne 0 ]; then
    return "$_E_CLI_PARSE_ERROR"
  fi

  eval set -- "$opts"
  case "$1" in
    --prefix | -p)
      PREFIX="$2"
      shift 2
      ;;
    --version | -v)
      VERSION="$2"
      shift 2
      ;;
    --force)
      force=true # since we have an existence check for when this is run internally, we want the ability to run it again
      ;;
    --)
      shift
      ;;
    *)
      printf "error: unknown option %s\n" "$1" >&2
      # shellcheck disable=SC2128 # FUNCNAME is a bash special variable
      printf "usage: %s [--version VERSION ] [ --prefix PREFIX ]\n" "$FUNCNAME" >&2
      return "$_E_CLI_PARSE_ERROR"
      ;;
  esac
  if ! command -v yq &> /dev/null || [ "$force" = "true" ]; then
    curl -fsSL "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64" -o "$/yq"
    chmod +x "$_common_bin/yq"
  fi
}
