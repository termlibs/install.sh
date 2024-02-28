i() {
    local zero_idx shell
    zero_idx="$1"
    shell="$(ps -p $$ -o cmd=)"
    if [[ "$shell" == *"zsh" ]]; then
        echo $(( $zero_idx + 1 ))
    elif [[ "$shell" == *"ash" ]]; then
        echo $(( $zero_idx ))
    else
        echo "unknown shell $shell"
        return 1
    fi
}

# get the current shell
SHELL=$(ps -p $$ -o args= | awk '{print $1}')

_get_machine_info() {
    # right now we are only linux x64
    export ARCH_x64="x86_64"
    export ARCH_AMD="amd64"
    export KERNEL="linux"
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

check_dependencies() {
    local all_installed=true
    for app in yq curl grep; do
        if ! command -v "$app" &>/dev/null; then
            printf "Error: %s is not installed\n" "$app" >&2
            all_installed=false
        fi
    done
    if ! $all_installed; then
        printf "Please install the missing dependencies and try again\n"
        exit 1
    fi
}

get_tempdir() {
    local tmpdir
    tmpdir="$(mktemp -dt "install-all-XXXXXX")"
    trap "rm -rf $tmpdir" EXIT
    echo "$tmpdir"
}

install_dependencies() {
set -x
    local tmp_working_dir
    tmp_working_dir="$(get_tempdir)"
    mkdir -p "$tmp_working_dir/bin"
    for dep in "${DEPENDENCIES[@]}"; do
        printf "Installing dependency %s\n" "$dep"
        case "$dep" in
            yq)
                filename="$(eval "echo \"${yq[$(i 2)]}\"")"
                curl -sSL "https://github.com/mikefarah/yq/releases/latest/download/$filename" -o "$tmp_working_dir/bin/yq"
                assert_executable "$tmp_working_dir/bin/yq"
                simple_install "$tmp_working_dir/bin/yq" "$PREFIX/bin/yq"
                return 0 ;;
            *)
                printf "Unknown dependency %s\n" "$dep"
                return 1 ;;
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

install_gh_repo_release() {
    local version repo
    repo="$1"
    latest="$(get_github_version_tag_from_latest "$repo")"
    curl  into this yq -oj '.assets[] | select( .name == "shfmt_v3.8.0_linux_amd64") | .browser_download_url'

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
