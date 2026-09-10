#!/usr/bin/env bash
# Print a JSON array of tools whose binaries may have changed between two commits.
# Rebuild everything when shared deps or build infrastructure changes, or when
# the base commit is missing (new branch / shallow clone). Documentation-only
# changes yield []. Use --all to force every tool (CI label ci:build-all).
#
# Path mapping is covered by scripts/ci-changed-tools-test.sh.
set -euo pipefail

usage() {
  echo "Usage: $0 <base-sha> <head-sha>" >&2
  echo "       $0 --all" >&2
  exit 2
}

list_all_tools() {
  local d
  for d in tools/*/; do
    [[ -d "$d" ]] || continue
    basename "$d"
  done | sort
}

json_array() {
  python3 -c 'import json, sys; print(json.dumps(sys.argv[1:]))' "$@"
}

all_tools=()
mapfile -t all_tools < <(list_all_tools)

if [[ "${1:-}" == "--all" ]]; then
  [[ $# -eq 1 ]] || usage
  echo "Forced full tool matrix" >&2
  json_array "${all_tools[@]}"
  exit 0
fi

[[ $# -eq 2 ]] || usage

base=$1
head=$2

if [[ -z "$base" || "$base" =~ ^0+$ ]]; then
  echo "No base commit; building all tools" >&2
  json_array "${all_tools[@]}"
  exit 0
fi

if ! git cat-file -e "${base}^{commit}" 2>/dev/null; then
  echo "Base commit ${base} not found; building all tools" >&2
  json_array "${all_tools[@]}"
  exit 0
fi

changed=$(git diff --name-only "${base}" "${head}")
echo "Changed files:" >&2
if [[ -z "$changed" ]]; then
  echo "  (none)" >&2
  echo '[]'
  exit 0
fi
printf '%s\n' "$changed" | sed 's/^/  /' >&2

selected=()
while IFS= read -r file; do
  [[ -n "$file" ]] || continue
  case "$file" in
    deps|deps/*)
      echo "Shared deps changed; building all tools" >&2
      json_array "${all_tools[@]}"
      exit 0
      ;;
    Makefile|.hadolint.yaml|scripts|scripts/*|.github/workflows|.github/workflows/*)
      echo "Build infrastructure changed; building all tools" >&2
      json_array "${all_tools[@]}"
      exit 0
      ;;
    tools/*)
      tool=${file#tools/}
      tool=${tool%%/*}
      if [[ -d "tools/${tool}" ]]; then
        selected+=("$tool")
      fi
      ;;
  esac
done <<< "$changed"

if ((${#selected[@]} == 0)); then
  echo "No tool, deps, or infrastructure changes; skipping binary builds" >&2
  echo '[]'
  exit 0
fi

mapfile -t selected < <(printf '%s\n' "${selected[@]}" | sort -u)
echo "Building tools: ${selected[*]}" >&2
json_array "${selected[@]}"
