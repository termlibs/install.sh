#!/usr/bin/env bash
#set -euo pipefail

_get_machine_info() {
  # right now we are only linux x64
  export ARCH_x64="x86_64"
  export ARCH_AMD="amd64"
  export KERNEL="linux"
}
_get_machine_info

TSV=$(
      cat << EOF
name	location	template	source
yq	mikefarah/yq	yq_${KERNEL}_${ARCH_AMD}	github
argocd	cli/cli	gh_\${ersion}_${KERNEL}_${ARCH_x64}.tar.gz	github
sh	mvdan/sh	shfmt_\${version}_${KERNEL}_${ARCH_AMD}	github
kubectl	kubernetes/kubernetes	kubernetes-client_\${version}_${KERNEL}_${ARCH_AMD}	github
EOF
)

app_lookup_name_from_repo() {
  local repo
  repo=$1
  app="$(echo "$TSV" | grep -P "	$repo\b" | awk '{print $1}')"
  if [ -z "$app" ]; then
    echo "error: no app found for $repo" >&2
    return 1
  fi
  echo "$app"
}

app_lookup() {
  local name result type_of
  name=$1
  type_of=$2
  case "$type_of" in
    "source")
      result="$(echo "$TSV" | grep -w "^$name" | awk '{print $4}')"
      ;;
    "location")
      result="$(echo "$TSV" | grep -w "^$name" | awk '{print $2}')"
      ;;
    "template")
      result="$(echo "$TSV" | grep -w "^$name" | awk '{print $3}')"
      ;;
    *)
      echo "error: no such column $type_of" >&2
      return 1
      ;;
  esac
  if [ -z "$result" ]; then
    echo "error: no $type_of found for $name" >&2
    return 1
  fi
  echo "$result"
}
