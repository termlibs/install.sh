# This function generates a git tag with a timestamp and the current git commit hash and status.
# the date format can be added as an argument though it defaults to +%Y%m%d-%H%M
git_tag_dated() {
  local rev rev_string full_rev_sring dateformat
  dateformat="${1:-+%Y%m%d-%H%M}"
  rev=$(git rev-parse --short HEAD)
  full_rev_string="$(git describe --broken --dirty --always)"
  rev_string="${full_rev_string/*$rev/$rev}" # strip any tags
  printf "%s-%s" "$(date "$dateformat")" "$rev_string"
}
