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
if [[ ${BASH_SOURCE[0]} == "${0}" ]]; then
  THIS="${0}"
else
  THIS=""
fi

# ERROR CODES
_E_GENERIC_ERROR=1
_E_CLI_PARSE_ERROR=11

_GITHUB="https://api.github.com"
# NOTES: jsonnet has more than one binary
read -d '' -r _APP_MD << MD # pretty
| shortname | repo               | source | file_pattern                            | archive_path                    | archive_depth |
|-----------|--------------------|--------|-----------------------------------------|---------------------------------|---------------|
| yq        | mikefarah/yq       | github | yq_linux_amd64                          | yq_linux_amd64                  | -1            |
| gh        | cli/cli            | github | gh_VERSION_linux_amd64.tar.gz           | gh_*_linux_amd64/bin/gh         | 2             |
| helm      | get.helm.sh        | url    | helm-vVERSION-linux-amd64.tar.gz        | linux-amd64/helm                | 1             |
| jsonnet   | google/go-jsonnet  | github | go-jsonnet_VERSION_Linux_x86_64.tar.gz  | jsonnet                         | 0             |
| shellcheck| koalaman/shellcheck| github | shellcheck-vVERSION.linux.x86_64.tar.xz | shellcheck-vVERSION/shellcheck  | 1             |
MD
_APP_MD="$(cat <<< "$_APP_MD" | sed -r 's/\ //g' | sed -r 's/\|/ /g')" # get us to single space separated

_create_venv() {
  :
}

_get_info() {
  local app shortname repo source file_pattern archive_path archive_depth
  #  set -x && trap 'set +x' EXIT
  app=$1
  while true; do
    IFS= read -r line
    read -r shortname repo source file_pattern archive_path archive_depth <<< "$line"
    case "$shortname" in
      "$app")
        break
        ;;
      "shortname")
        if [ "$app" == "_keys" ]; then
          break
        fi
        continue
        ;;
      "")
        printf "error: unable to find info for app '%s'\n" "$app" >&2
        return 1
        ;;
      *)
        continue
        ;;
    esac
  done <<< "$_APP_MD"
  printf "%s %s %s %s %s %s\n" "${shortname@Q}" "${repo@Q}" "${source@Q}" "${file_pattern@Q}" "${archive_path@Q}" "${archive_depth@Q}"
}

_is_archive() {
  local path
  path="${1}"
  case "$path" in
    *.tar | *.tar.gz | *.tgz | *.zip | *.tar.xz)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

_save_bin() {
  local path archive_path archive_depth app bin_path
  # try to read from stdin
  # evals are used here because these are shell quoted strings
  eval app="${1}"
  path="${2}/${shortname}"
  version="${3}"
  shortname="${4}"
  file_pattern="${5}"
  archive_path="${6}"
  archive_depth="${7}"
  printf "DEBUG: path=%s archive_path=%s archive_depth=%s app=%s version=%s\n" "$path" "$archive_path" "$archive_depth" "$app" "${version@Q}" >&2
  if [ -z "$archive_depth" ] || [ "$archive_depth" -lt 0 ]; then
    cat > "$path" < /dev/stdin
    return 0
  fi
  with-tempdir cd "$_TEMPDIR"
  mkdir "$app" && cd "$app"
  echo "$file_pattern"
  case "$archive_path" in
    *.tar)
      tar --strip-components="$archive_depth" -Oxf - "$archive_path" > "$shortname" < /dev/stdin
      ;;
    *.tar.gz | *.tgz)
      tar --strip-components="$archive_depth" -Oxzf - "$archive_path" > "$shortname" < /dev/stdin
      ;;
    *.zip)
      unzip -d "$archive_path" - < /dev/stdin #  todo components i forget the syntax offhand
      ;;
    *.tar.xz)
      xz -d --stdout -q | tar --strip-components="$archive_depth" -Oxf - "$archive_path" > "$shortname" < /dev/stdin
      ;;
    *)
      return 1
      ;;
  esac
  find .
  if [ "$(ls -1 | wc -l)" -ne 1 ]; then
    printf "error: expected only one file in archive, found %s\n" "$(ls -1 | wc -l)" >&2
    return 1
  fi
  bin_path="$(ls -1)"
  chmod +x "$bin_path"
  mv "$bin_path" "$path"
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
  _assert_yq || return 1
  cat - | yq ".assets[] | select(.name | test(\"$1\$\")) | .browser_download_url"
}

# we have our own special function here since we use it in the other install functions
_assert_yq() {
  if ! command -v yq &> /dev/null || [ "$force" = "true" ]; then
    # install to temp since the user hasn't explicitly asked to install this
    with-tempdir mkdir -p "$_TEMPDIR/bin"
    _urlget "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64" > "$_TEMPDIR/bin/yq"
    chmod +x "$_TEMPDIR/bin/yq"
    export PATH="$PATH:$_TEMPDIR/bin" # add to the path for the duration of the run
  fi
}

_build_link() {
  local asset_match_pattern vversion response url __
  _assert_yq || return 1
  local version="$2"
  local line="$(_get_info "$1")"
  eval line="( $line )"
  read -r shortname repo source file_pattern archive_path archive_depth <<< "${line[*]}"
  [ -z "$version" ] && version="$( _get_latest_vversion "$shortname" )"
  version="${version#v}"
  vversion="v${version}"
  response="$(_urlget "$_GITHUB/repos/$repo/releases/tags/$vversion")"
  asset_match_pattern="${file_pattern/VERSION/${version}}"
  url="$(_link_from_release_by_pattern "$asset_match_pattern" <<< "$response")"
  [ -z "$url" ] && return 1
  printf "%s\n" "$url"
}

_get_latest_vversion() {
  local asset_match_pattern tag vversion response url __
  _assert_yq || return 1
  local app="$1"
  local version="$2"
  read -r shortname repo source file_pattern archive_path archive_depth <<< "$(_get_info "$app")"
  eval shortname="$shortname" repo="$repo" source="$source" file_pattern="$file_pattern" archive_path="$archive_path" archive_depth="$archive_depth"
  if [ -n "$version" ] && [ "$version" != "latest" ]; then
    # just in case we are sending in one explicitly somewhere
    printf "v%s\n" "${version#v}"
    return 0
  else
    version="latest"
  fi
  response="$(_urlget "$_GITHUB/repos/$repo/releases/latest")"
  asset_match_pattern="${file_pattern/VERSION/.*}"
  url="$(_link_from_release_by_pattern "$asset_match_pattern" <<< "$response")"
  version="$(grep -oP 'v\d+\.\d+\.\d+(-[a-zA-Z0-9.])?' <<< "$url")" # this probably if it's semver, will figure out a non hacky way later
  vversion="v${version#v}"
  printf "%s\n" "$vversion"
}

_download_release() {
  local app version download_url
  app=$1
  version=$2
  eval R="( $(_get_info "$app") )"
  read -r shortname repo source file_pattern archive_path archive_depth <<< "${R[@]}"
  case "$source" in
    "github")
      download_url="$(_build_link "$app" "$version")"
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
  set -x
  local download_link
  local opts PREFIX VERSION force download_link
  opts="$(getopt -o "fv:p:" --long "force,version:,prefix:" -n "${FUNCNAME[0]}" -- "$@")"
  # shellcheck disable=SC2181
  [ "$?" -ne 0 ] && return "$_E_CLI_PARSE_ERROR"
  eval set -- "$opts"

  if [ -d "$HOME/.local" ]; then
    PREFIX="$HOME/.local"
  else
    PREFIX="$PWD"
  fi
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
      shift
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
  local app="$1"
  [ -d "$PREFIX/bin" ] || mkdir -p "$PREFIX/bin"

  read -r shortname repo source file_pattern archive_path archive_depth <<< "$(_get_info "$app")"
  eval shortname="$shortname" repo="$repo" source="$source" file_pattern="$file_pattern" archive_path="$archive_path" archive_depth="$archive_depth"
  download_link="$(_build_link "$app" "$VERSION")" || return 1
  curl -fsSL "$download_link" | _save_bin \
    "$app" \
    "$PREFIX/bin" \
    "$VERSION" \
    "$shortname" \
    "$file_pattern" \
    "$archive_path" \
    "$archive_depth"
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

if [[ ${BASH_SOURCE[0]} == "${0}" ]]; then
  "$@"
fi
