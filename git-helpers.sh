git-tag-dated() {
    local datefmt
    local datestamp
    local gitref
    local tag
    datefmt="${1:-+%Y%m%d-%H%M}"
    datestamp="$(date "$datefmt")"
    gitref="$(git rev-parse --short HEAD)"
    tag="${datestamp}-${gitref}"
    echo -n "${tag}"
    if ! [ "$(git status --short)" = "" ]; then
        echo '-dirty'
    else
        echo
    fi
}