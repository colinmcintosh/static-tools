#!/usr/bin/env bash
# Assert a binary is statically linked and a PIE (ET_DYN, no INTERP).
#
# Usage:
#   scripts/assert-static-elf.sh <binary> [binary...]
#
set -euo pipefail

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <binary> [binary...]" >&2
    exit 2
fi

if ! command -v readelf >/dev/null 2>&1; then
    echo "ERROR: readelf is required" >&2
    exit 1
fi

for bin in "$@"; do
    if [[ ! -e "${bin}" ]]; then
        echo "ERROR: ${bin} not found" >&2
        exit 1
    fi
    if readelf -l "${bin}" | grep -q INTERP; then
        echo "ERROR: ${bin} is not static (INTERP present)" >&2
        readelf -l "${bin}" >&2
        exit 1
    fi
    if ! readelf -h "${bin}" | grep -q 'Type:[[:space:]]*DYN'; then
        echo "ERROR: ${bin} is not a PIE (expected ET_DYN)" >&2
        readelf -h "${bin}" >&2
        exit 1
    fi
    echo "✓ ${bin} is a static PIE"
done
