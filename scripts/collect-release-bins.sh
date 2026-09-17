#!/usr/bin/env bash
# Copy release binaries out of a downloaded-artifacts tree and check that the
# set of names is exactly `make print-artifacts`.
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
find "${src}" -type f \( -name '*-amd64' -o -name '*-arm64' \) ! -path "${src}/deps-prefix-*/*" -exec cp {} "${dest}/" \;

if ! diff -u \
    <(make -s --no-print-directory -C "${ROOT}" print-artifacts | tr ' ' '\n' | sort) \
    <(find "${dest}" -maxdepth 1 -type f \( -name '*-amd64' -o -name '*-arm64' \) -printf '%f\n' | sort) >&2; then
    echo "::error::Release binaries in ${src} do not match 'make print-artifacts' (- expected, + found)" >&2
    exit 1
fi

find "${dest}" -maxdepth 1 -type f \( -name '*-amd64' -o -name '*-arm64' \) -printf '%f\n' | sort
