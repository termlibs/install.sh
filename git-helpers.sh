# This function generates a git tag with a timestamp and the current git commit hash.
# If there are any uncommitted changes, or any other weird situation, '-dirty' is appended to the tag.
# the date format can be added as an argument though it defaults to +%Y%m%d-%H%M
git-tag-dated() {
    local dateformat
    local datestamp
    local shortref
    local tag
    dateformat="${1:-+%Y%m%d-%H%M}"
    datestamp="$(date "$dateformat")"
    shortref="$(git rev-parse --short HEAD)" || { echo "Failed to get git commit hash, are you in a git repository?"; exit 1; }
    tag="${datestamp}-${shortref}"
    # if there are any difference, regardless of what they are, the tag is marked dirty
    if ! [ "$(git status --short)" = "" ]; then
        tag="${tag}-dirty"
    fi
    echo -n "${tag}"
}