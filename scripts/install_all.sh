#!/usr/bin/env bash

# shellcheck disable=SC2155 #_TEMPDIR if we need it, only create if we don't have it
_TEMPDIR="$(mktemp -dut install-all-XXXXXX)"
trap '[ -d "$_TEMPDIR" ] && rm -rf "$_TEMPDIR"' EXIT
with-tempdir() {
  if ! [ -d "$_TEMPDIR" ]; then
    mkdir "$_TEMPDIR" || exit 99 # if we need the temp and can't use it then we should exit
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

_GITHUB="https://github.com"
_GITHUB_API="https://api.github.com"
# NOTES:
# - jsonnet has more than one binary, but we only get the jsonnet app for now
# - if something has the word VERSION in it originally, i guess we're screwed
read -d '' -r _APP_MD << MD # pretty
| shortname  | repo                   | source | file_pattern                                        | archive_path                   | archive_depth | custom_release_tag |
|------------|------------------------|--------|-----------------------------------------------------|--------------------------------|---------------|--------------------|
| yq         | mikefarah/yq           | github | yq_linux_amd64                                      | -                              | -             | -                  |
| jq         | jqlang/jq              | github | jq-linux-amd64                                      | -                              | -             | jq-VERSION         |
| gh         | cli/cli                | github | gh_VERSION_linux_amd64.tar.gz                       | gh_*_linux_amd64/bin/gh        | 2             | -                  |
| helm       | get.helm.sh            | url    | helm-vVERSION-linux-amd64.tar.gz                    | linux-amd64/helm               | 1             | -                  |
| jsonnet    | google/go-jsonnet      | github | go-jsonnet_VERSION_Linux_x86_64.tar.gz              | jsonnet                        | 0             | -                  |
| shellcheck | koalaman/shellcheck    | github | shellcheck-vVERSION.linux.x86_64.tar.xz             | shellcheck-vVERSION/shellcheck | 1             | -                  |
| shfmt      | mvdan/sh               | github | shfmt_vVERSION_darwin_amd64                         | -                              | -             | -                  |
| terraform  | releases.hashicorp.com | url    | terraform/VERSION/terraform_VERSION_linux_amd64.zip | terraform                      | 0             | -                  |
| yutc       | adam-huganir/yutc      | github | yutc-linux-amd64                                    | -                              | -             | -                  |
| glances    | -                      | pip    | glances                                             | -                              | -             | -                  |
MD
_APP_MD="$(cat <<< "$_APP_MD" | sed -r 's/\ //g' | sed -r 's/\|/ /g')" # get us to single space separated

_create_venv() {
  :
}

_get_info() {
  local app shortname repo source file_pattern archive_path archive_depth custom_release_tag
  #  set -x && trap 'set +x' EXIT
  app=$1
  while true; do
    IFS= read -r line
    read -r shortname repo source file_pattern archive_path archive_depth custom_release_tag <<< "$line"
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
        return $_E_GENERIC_ERROR
        ;;
      *)
        continue
        ;;
    esac
  done <<< "$_APP_MD"
  printf "%s %s %s %s %s %s %s\n" "${shortname@Q}" "${repo@Q}" "${source@Q}" "${file_pattern@Q}" "${archive_path@Q}" "${archive_depth@Q}" "${custom_release_tag@Q}"
}

_is_archive() {
  local path
  path="${1}"
  case "$path" in
    *.tar | *.tar.gz | *.tgz | *.zip | *.tar.xz)
      return 0
      ;;
    *)
      return $_E_GENERIC_ERROR
      ;;
  esac
}

_save_bin() {
  local path archive_path archive_depth custom_release_tag app bin_path version file_pattern shortname app
  # set -x && trap 'set +x' EXIT
  # try to read from stdin
  # evals are used here because these are shell quoted strings
  eval app="${1}"
  path="${2}/${4}"
  version="${3}"
  shortname="${4}"
  file_pattern="${5}"
  archive_path="${6}"
  archive_depth="${7}"
  printf "DEBUG: path=%s archive_path=%s archive_depth=%s app=%s version=%s\n" "$path" "$archive_path" "$archive_depth" "$app" "${version@Q}" >&2
  if [ -z "$archive_depth" ] || [[ "$archive_depth" == "-" ]]; then
    cat > "$path" < /dev/stdin
    return 0
  fi
  with-tempdir cd "$_TEMPDIR"
  mkdir "$app" && cd "$app"

  case "$file_pattern" in
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
      return $_E_GENERIC_ERROR
      ;;
  esac

  if [ "$(ls -1 | wc -l)" -ne 1 ]; then
    printf "error: expected only one file in archive, found %s\n" "$(ls -1 | wc -l)" >&2
    return $_E_GENERIC_ERROR
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
    return $_E_GENERIC_ERROR
  fi
}

_link_from_release_by_pattern() {
  _assert_yq || return $_E_GENERIC_ERROR
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
  local asset_match_pattern version vversion response url
  _assert_yq || return $_E_GENERIC_ERROR
  local version="$2"
  local line="$(_get_info "$1")"
  eval line="( $line )"
  read -r shortname repo source file_pattern archive_path archive_depth custom_release_tag <<< "${line[*]}"
  [ -z "$version" ] && version="$(_get_latest_vversion "$shortname")"
  version="${version#v}"
  vversion="v${version}"
  response="$(_urlget "$_GITHUB_API/repos/$repo/releases/tags/$vversion")"
  asset_match_pattern="${file_pattern/VERSION/${version}}"
  url="$(_link_from_release_by_pattern "$asset_match_pattern" <<< "$response")"
  [ -z "$url" ] && return $_E_GENERIC_ERROR
  printf "%s\n" "$url"
}

_get_latest_vversion() {
  local asset_match_pattern tag vversion response url __
  _assert_yq || return $_E_GENERIC_ERROR
  local app="$1"
  local version="$2"
  read -r shortname repo source file_pattern archive_path archive_depth custom_release_tag <<< "$(_get_info "$app")"
  eval shortname="$shortname" repo="$repo" source="$source" file_pattern="$file_pattern" archive_path="$archive_path" archive_depth="$archive_depth"
  if [ -n "$version" ] && [ "$version" != "latest" ]; then
    # just in case we are sending in one explicitly somewhere
    printf "v%s\n" "${version#v}"
    return 0
  else
    version="latest"
  fi
  response="$(_urlget "$_GITHUB_API/repos/$repo/releases/latest")"
  asset_match_pattern="${file_pattern/VERSION/.*}"
  url="$(_link_from_release_by_pattern "$asset_match_pattern" <<< "$response")"
  version="$(grep -oPm 1 'v\d+\.\d+\.\d+(-[a-zA-Z0-9.])?' <<< "$url" | uniq)" # this probably if it's semver, will figure out a non hacky way later
  if [ "$(wc -l <<< "$version")" -ne 1 ]; then
    printf "error: unable to determine version from url\n" >&2
    return $_E_GENERIC_ERROR
  fi
  vversion="v${version#v}"
  printf "%s\n" "$vversion"
}

_download_release() {
  local app version download_url
  app=$1
  version=$2
  eval R="( $(_get_info "$app") )"
  read -r shortname repo source file_pattern archive_path archive_depth custom_release_tag <<< "${R[@]}"
  case "$source" in
    "github")
      download_url="$(_build_link "$app" "$version")"
      ;;
    "url")
      # TODO: helm/terraform special_case_goes_here  for grabbing version
      if [ -n "$version" ] && [ "$version" != "latest" ]; then
        printf "error: version %s not supported for %s\n" "$version" "$app" >&2
        return $_E_GENERIC_ERROR
      fi
      download_url="https://${repo}/${file_pattern/VERSION/$version}"
      ;;
    *)
      echo "error: unknown source type $source" >&2
      return $_E_GENERIC_ERROR
      ;;
  esac
  _urlget "$download_url"
}

install-it() {
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
  while true; do
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
        break
        ;;
      *)
        printf "error: unknown option %s\n" "$1" >&2
        # shellcheck disable=SC2128 # FUNCNAME is a bash special variable
        printf "usage: %s [--version VERSION ] [ --prefix PREFIX ]\n" "$FUNCNAME" >&2
        return "$_E_CLI_PARSE_ERROR"
        ;;
    esac
  done
  local app="$1"
  [ -d "$PREFIX/bin" ] || mkdir -p "$PREFIX/bin"

  set -x
  read -r shortname repo source file_pattern archive_path archive_depth custom_release_tag <<< "$(_get_info "$app")"
  eval shortname="$shortname" repo="$repo" source="$source" file_pattern="$file_pattern" archive_path="$archive_path" archive_depth="$archive_depth"
  download_link="$(_build_link "$app" "$VERSION")" || return $_E_GENERIC_ERROR
  curl -fsSL "$download_link" | _save_bin \
    "$app" \
    "$PREFIX/bin" \
    "$VERSION" \
    "$shortname" \
    "$file_pattern" \
    "$archive_path" \
    "$archive_depth"
}

_install_yq() {
  with-tempdir mkdir -p "$_TEMPDIR/bin"
  curl -fsSL "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64" -o "$_TEMPDIR/bin/yq"
  export PATH="$PATH:$_TEMPDIR/bin" # add to the path for the duration of the run
}

print_supported_apps() {
  while true; do
    IFS= read -r line
    read -r shortname repo source file_pattern archive_path archive_depth custom_release_tag <<< "$line"
    if [[ ${shortname:0:1} == "-" ]] || [[ $shortname == "shortname" ]]; then
      continue
    elif [ -z "$shortname" ]; then
      break
    fi
    printf "  - %-15s from " "$shortname"
    if [[ $source == github ]]; then
      printf "$_GITHUB/%s" "$repo"
    elif [[ $source == url ]]; then
      printf "https://%s " "$repo"
    else
      printf "unknown source: %s " "$source"
    fi
    printf "\n"
  done <<< "$_APP_MD"
}

install() {
  local opts PREFIX VERSION force USAGE
  opts="$(getopt -o "fv:p:" --long "help,force,version:,prefix:" -n "${FUNCNAME[0]}" -- "$@")"
  # shellcheck disable=SC2181
  [ $? -ne 0 ] && return "$_E_CLI_PARSE_ERROR"

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
    --help)
      # command help
      printf "$USAGE\n"
      printf "\tinstall an app\n\n"
      printf "options:\n"
      printf "\t--version VERSION\tthe version to install, defaults to latest\n"
      printf "\t--prefix  PREFIX \tthe prefix to install to, defaults to \$HOME/.local\n"
      printf "\t--force\t        \tforce install even if already installed (or update to a version)\n"
      printf "\t--help\t         \tshow this help\n"
      printf "\n"
      printf " currently supported apps:\n"
      print_supported_apps
      return
      ;;
    --)
      shift
      ;;
    *)
      exit 1 # should never happen, getopt should fail with an error
      ;;
  esac
}

if [[ ${BASH_SOURCE[0]} == "${0}" ]] ; then
  "$@"
fi
