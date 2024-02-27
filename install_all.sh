#!/usr/bin/env bash
# set -eo pipefail
PREFIX="${PREFIX:-/usr/local}"


# get some curl headers if we need them
GH_TOKEN="${GH_TOKEN:-}"
gh_auth=()
if [ -n "$GH_TOKEN" ]; then
    gh_auth=("-H" "Authorization: Bearer $GH_TOKEN")
fi

# stubbing these in, the logic will need work if these are actually dynamic
arch_x64="$(uname -m)"
arch_amd64="$(if [ "$arch_x64" = "x86_64" ]; then echo "amd64"; else echo "$arch_x64"; fi)"
kernel="$( if [ "$(uname -s)" == "Linux" ]; then echo "linux"; else echo "$(uname -s)"; fi )"

# common_variables
version=""
ersion="" # without the v lol

github_apps_fname_lookup=()
github_apps_fname_lookup["gh"]='gh_${ersion}_${kernel}_${arch_x64}.tar.gz'
github_apps_fname_lookup["yq"]='yq_${kernel}_${arch_amd64}'

assert_executable() { chmod +x "$1"; }
simple_install() {
    local src dest
    src="$1"
    dest="$2"
    mkdir -p "$(dirname "$dest")"
    mv "$src" "$dest"
    assert_executable "$dest"
}

tmp_working_dir="$(mktemp -d installer.XXXXXX)"
mkdir -p "$tmp_working_dir/"{bin,installing}
trap 'rm -rf "$tmp_working_dir"' EXIT

# check this first, since we will probably want to use this later to install other things
if [ "$1" == "--install-yq" ]; then
    filename="$(eval 'echo "${github_apps_fname_lookup[yq]}"')"
    curl -sSL "https://github.com/mikefarah/yq/releases/latest/download/$filename" -o "$tmp_working_dir/bin/yq"
    assert_executable "$tmp_working_dir/bin/yq"
    simple_install "$tmp_working_dir/bin/yq" "$PREFIX/bin/yq"
    exit 0
fi

all_installed=true
for app in curl grep; do
    if ! command -v "$app" &>/dev/null; then
        printf "Error: %s is not installed\n" "$app" >&2
        all_installed=false
    fi
done
if ! $all_installed; then
    printf "Please install the missing dependencies and try again\n"
    exit 1
fi


get_version_tag_from_latest() {
    local repo tag
    repo="$1"
    tag="$(curl -s "https://api.github.com/repos/$repo/releases/latest" | grep -Po '"tag_name": "\K.*?(?=")')"
    ersion="${tag#v}"
    version="v${ersion}"
    echo "$tag"

}

install_gh_repo_release() {
    local version repo
    repo="$1"
    latest="$(get_version_tag_from_latest "$repo")"
    version="${2:-$latest}"
}

# install github
install_gh_cli() {
    local version
    version="${1:-latest}"
    install_gh_repo_release "cli/cli" "$version"
}

# handle_tar() {

# }

# install_gh cli/cli
