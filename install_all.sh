#!/usr/bin/env bash
set -euo pipefail

# declare common variables we will use later
version=""
ersion="" # without the v lol


_get_machine_info() {
    # right now we are only linux x64
    ARCH_x64="x86_64"
    ARCH_AMD="amd64"
    KERNEL="linux"
}
assert_executable() { chmod +x "$1"; }
simple_install() {
    local src dest
    src="$1"
    dest="$2"
    mkdir -p "$(dirname "$dest")"
    mv "$src" "$dest"
    assert_executable "$dest"
}

_get_machine_info

app_table=( yq gh shfmt )
export DEPENDENCIES=( yq )
# app   source              url/repo                               artifact-format
yq=(   "github"           "mikefarah/yq"                           'yq_${KERNEL}_${ARCH_AMD}' )
gh=(   "github"           "cli/cli"                                'gh_${ersion}_${KERNEL}_${ARCH_x64}.tar.gz' )
shfmt=( "github"          "mvdan/sh"                               'shfmt_${version}_${KERNEL}_${ARCH_AMD}' )

SHORT_OPTS="h"
LONG_OPTS="help,install-dependencies,prefix:"

ARGS=$(getopt -o "$SHORT_OPTS" --long "$LONG_OPTS" -n "$(basename $0)" -- "$@")
if [ $? -ne 0 ]; then print "Unable to parse options... ttyl" ; exit 1; fi
eval set -- "$ARGS"

PREFIX="$PWD/tmp"

while true; do
    case "$1" in
        --install-dependencies)
            INSTALL_DEPENDENCIES=true
            shift
            ;;
        --prefix)
            PREFIX="$2"
            shift 2
            ;;
        -h|--help)
            HELP=true
            shift
            ;;
        --)
            shift
            break
            ;;
        install)
            INSTALL=true
            shift
            break
            ;;
        *)
            echo "Internal error!"
            exit 1
            ;;
    esac
done
tmp_working_dir="$(mktemp -d installer.XXXXXX)"
mkdir -p "$tmp_working_dir/"{bin,installing}
trap 'rm -rf "$tmp_working_dir"' EXIT


if [ "$INSTALL_DEPENDENCIES" = true ]; then

fi


# install github
install_gh_cli() {
    local version
    version="${1:-latest}"
    install_gh_repo_release "cli/cli" "$version"
}

# handle_tar() {

# }

# install_gh cli/cli
