# shellcheck disable=SC2064
. ./header.sh

idx() {
  # bash is 0 zero indexed, most other shells are 1 indexed
  # this corrects it (sic) to 1 indexed
  local zero_idx shell
  zero_idx="$1"
  shell="$(ps -p $$ -o cmd=)"
  if [[ "$shell" == *"ash" ]]; then
    echo $((zero_idx + 1))
  else
    echo $((zero_idx))
  fi
}

# get the current shell



assert_executable() { chmod +x "$1"; }
simple_install() {
  local src dest
  src="$1"
  dest="$2"
  mkdir -p "$(dirname "$dest")"
  mv "$src" "$dest"
  assert_executable "$dest"
}

check_dependencies() {
  local all_installed=true
  for app in yq curl grep; do
    if ! command -v "$app" &> /dev/null; then
      printf "Error: %s is not installed\n" "$app" >&2
      all_installed=false
    fi
  done
  if [[ $all_installed == "false" ]]; then
    printf "Please install the missing dependencies and try again\n"
    return 1
  fi
}

get_tempdir() {
  local tmpdir
  tmpdir="$(mktemp -dt "install-all-XXXXXX")"
  echo "$tmpdir"
}

install_dependencies() {
  local tmp_working_dir
  tmp_working_dir="$(get_tempdir)"
  trap "rm -rf $tmp_working_dir" RETURN
  mkdir -p "$tmp_working_dir/bin"
  for dep in "${DEPENDENCIES[@]}"; do
    printf "Installing dependency %s\n" "$dep"
    case "$dep" in
      yq)
        filename="yq_linux_amd64"
        curl -sSL "https://github.com/mikefarah/yq/releases/latest/download/$filename" -o "$tmp_working_dir/bin/yq"
        assert_executable "$tmp_working_dir/bin/yq"
        simple_install "$tmp_working_dir/bin/yq" "$PREFIX/bin/yq"
        return 0
        ;;
      *)
        printf "Unknown dependency %s\n" "$dep"
        return 1
        ;;
    esac
  done
}

get_ersion() {
  echo "${1#v}"
}

get_github_version_from_latest() {
  local repo tag
  repo="$1"
  tag="$(curl -s "https://api.github.com/repos/$repo/releases/latest" | grep -Po '"tag_name": "\K.*?(?=")')"
  version="v${tag#v}"
  echo "$version"
}

extract_download_url() {
  stdin="$(cat)"
  if command -v python3 &> /dev/null; then
    echo "$stdin" | _extract_download_url_python "$1"
  else
    echo "$stdin" | _extract_download_url_yq "$1"
  fi
}

_extract_download_url_yq() {
  stdin="$(cat)"
  echo "$stdin" \
    | yq -roj ".assets[] | select( .name == \"${1}\") | .browser_download_url"
}

_extract_download_url_python() {
  stdin="$(cat)"
  tempfile="$(mktemp)"
  trap "rm -f $tempfile" RETURN
  cat > "$tempfile" << PY
import sys, json
data = json.loads(sys.stdin.read())
for asset in data["assets"]:
    if asset["name"] == sys.argv[1]:
        print(asset["browser_download_url"])
        quit()
PY
  echo "$stdin" | python "$tempfile" "$1"
}

download_to() {
  local url dest
  url="$1"
  dest="$2"
  curl -sfSL "$url" -o "$dest"
}

install_gh_repo_release() {
  local version repo latest_version file_format
  repo="$1"
  file_format="$2"
  version="${3:-latest}"
  if [[ "$file_format" == *"ersion"* ]]; then
    # we may need the version before requesting the latest file
    if [[ "$version" == "latest" ]]; then
      version="$(get_github_version_from_latest "$repo")"
    else
      # make sure it starts with a v
      version="v${version#v}"
    fi
    version="$(get_github_version_from_latest "$repo")"
  fi
  filename="$(eval "echo $file_format")"
  if [[ "$version" == "latest" ]]; then
    url="https://api.github.com/repos/$repo/releases/latest"
  else
    url="https://api.github.com/repos/$repo/releases/tags/$version"
  fi
  download_url="$(curl -sfSL "$url" | extract_download_url "$filename")"
}

# install github
install_gh_cli() {
  local version
  version="${1:-latest}"
  install_gh_repo_release "cli/cli" "$version"
}

install_this() {
  local to_install location version
  to_install="$1"
  location="$(app_lookup "$to_install" "location")"
  if [[ -z "$location" ]]; then
    to_install="$(app_lookup_name_from_repo "$to_install")"
    location="$(app_lookup "$to_install" "location")"    
  fi
  if [[ -z "$location" ]]; then
    printf "Could not find %s\n" "$to_install"
    return 1
  fi
  src="$(app_lookup "$to_install" "source")"
  template="$(app_lookup "$to_install" "template")"
  
  version="${4:-latest}"
  case "$src" in
    github)
      install_gh_repo_release "$location" "$template" "$version"
      ;;
    *)
      printf "Unknown source %s\n" "$src"
      return 1
      ;;
  esac
}

_ask() {
  local yn
  if [ -n "${quiet:-}" ]; then
    return 0
  fi

  read -r -p "> $1: " yn
  case $yn in
    [Yy]* | "")
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

install_kubectl() {
  local version
  version="${1:-latest}"
  if [[ "$version" == "latest" ]]; then
    version="$(curl -L -s https://dl.k8s.io/release/stable.txt)"
  fi
  ersion="${version#v}"
  download_to "https://dl.k8s.io/release/v${ersion}/bin/linux/amd64/kubectl" "$PREFIX/bin/kubectl"
  assert_executable "$PREFIX/bin/kubectl"
}

install_helm() {
  local version
  version="${1:-latest}"
  if [[ "$version" == "latest" ]]; then
    version="$(get_github_version_from_latest "helm/helm")"
  fi
  tmpdir="$(get_tempdir)"
  trap "rm -rf $tmpdir" RETURN
  filename="helm-v${version#v}-linux-amd64.tar.gz"
  download_to "https://get.helm.sh/$filename" "$tmpdir/$filename"
  tar -C "$tmpdir" -xzf "$tmpdir/$filename" "linux-amd64/helm"
  simple_install "$tmpdir/linux-amd64/helm" "$PREFIX/bin/helm"
}

try_your_best() {
  in="$1"
  result="$(grep "$ARCH_x86" <<< "$in")"
  if [ "$(wc -l <<< $result)" -eq 1 ]; then
    echo "$result"
  fi
  result="$(grep "$ARCH_AMD" <<< "$in")"
  if [ "$(wc -l <<< $result)" -eq 1 ]; then
    echo "$result"
  fi
  result="$(grep -i "$KERNEL" <<< "$result")"
  if [ "$(wc -l <<< $result)" -eq 1 ]; then
    echo "$result"
  fi
  echo "Could not find a match"
  return 1
}

extract_binary() {
  # kinda works if it's top level
  archive="$1"
  destination="$2"
  exec_files="$(tar -v -tf "$1" | grep -P '\-rwx')"
  if [ "$(wc -l <<< "$exec_files")" -eq 1 ]; then
    filename="$(echo "$exec_files" | cut -d\  -f 6)"
    tar -C "$destination" -xzf "$archive" "$filename"
    return 0
  fi
  return 1
}