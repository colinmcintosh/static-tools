#!/usr/bin/env bash
# Print a JSON array of tools whose binaries may have changed between two commits.
# Rebuild everything when the shared deps prefix changes, or when the base
# commit is missing (new branch / shallow clone).
set -euo pipefail

usage() {
  echo "Usage: $0 <base-sha> <head-sha>" >&2
  exit 2
}

[[ $# -eq 2 ]] || usage

base=$1
head=$2

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
  echo "No tool or deps changes; skipping binary builds" >&2
  echo '[]'
  exit 0
fi

mapfile -t selected < <(printf '%s\n' "${selected[@]}" | sort -u)
echo "Building tools: ${selected[*]}" >&2
json_array "${selected[@]}"
