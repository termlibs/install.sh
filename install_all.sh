# declare common variables we will use later
version=""
ersion="" # without the v lol

_get_machine_info

app_table=(yq gh shfmt)
export DEPENDENCIES=(yq)
# app   source              url/repo                               artifact-format
yq=("github" "mikefarah/yq" 'yq_${KERNEL}_${ARCH_AMD}')
gh=("github" "cli/cli" 'gh_${ersion}_${KERNEL}_${ARCH_x64}.tar.gz')
shfmt=("github" "mvdan/sh" 'shfmt_${version}_${KERNEL}_${ARCH_AMD}')

SHORT_OPTS="h"
LONG_OPTS="help,install-dependencies,prefix:"



ARGS=$(getopt -o "$SHORT_OPTS" --long "$LONG_OPTS" -n "$(basename $0)" -- "$@")
if [ $? -ne 0 ]; then
  print "Unable to parse options... ttyl"
  exit 1
fi
eval set -- "$ARGS"

PREFIX="$HOME/.local"

INSTALL_DEPENDENCIES="false"
HELP="false"
INSTALL="false"
while true; do
  case "$1" in
    --install-dependencies)
      INSTALL_DEPENDENCIES=true
      shift
      ;;
    --prefix)
      #            PREFIX="$2"
      PREFIX="$PWD" # for testing
      shift 2
      ;;
    -h | --help)
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

if [ "$INSTALL_DEPENDENCIES" = true ]; then install_dependencies; fi

main() {
  echo "Installing dependencies"
}

. install_all.func.sh

main
