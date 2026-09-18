#!/usr/bin/env bash
# Copy release binaries out of a downloaded-artifacts tree and check that the
# set of names is exactly `make print-artifacts`. A name found in more than
# one artifact fails instead of the last copy silently winning, so one tool's
# build cannot replace another tool's binary.
#
# Usage:
#   ./scripts/collect-release-bins.sh SRC_DIR DEST_DIR
set -euo pipefail

if [[ $# -ne 2 ]]; then
    echo "Usage: $0 SRC_DIR DEST_DIR" >&2
    exit 2
fi

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
src=$1
dest=$2

mkdir -p "${dest}"
if [[ -n "$(find "${dest}" -mindepth 1 -maxdepth 1 -print -quit)" ]]; then
    echo "::error::${dest} must be empty" >&2
    exit 1
fi
while IFS= read -r -d '' file; do
    name=${file##*/}
    if [[ -e "${dest}/${name}" ]]; then
        echo "::error::${name} appears in more than one artifact under ${src}" >&2
        exit 1
    fi
    cp "${file}" "${dest}/${name}"
done < <(find "${src}" -type f \( -name '*-amd64' -o -name '*-arm64' \) ! -path "${src}/deps-prefix-*/*" -print0)

if ! diff -u \
    <(make -s --no-print-directory -C "${ROOT}" print-artifacts | tr ' ' '\n' | sort) \
    <(find "${dest}" -maxdepth 1 -type f \( -name '*-amd64' -o -name '*-arm64' \) -printf '%f\n' | sort) >&2; then
    echo "::error::Release binaries in ${src} do not match 'make print-artifacts' (- expected, + found)" >&2
    exit 1
fi

find "${dest}" -maxdepth 1 -type f \( -name '*-amd64' -o -name '*-arm64' \) -printf '%f\n' | sort
