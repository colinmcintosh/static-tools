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
    # musl static-pie applies only *RELATIVE relocs. Leftover TLS/symbolic
    # relocs stay as zeros and crash (BIND isc_tid_v R_*_TPOFF* on amd64).
    if bad_relocs="$(readelf -Wr "${bin}" | awk '
        $3 ~ /^R_/ && $3 !~ /RELATIVE$/ { print }
    ')" && [[ -n "${bad_relocs}" ]]; then
        echo "ERROR: ${bin} has relocs musl static-pie cannot apply:" >&2
        echo "${bad_relocs}" >&2
        exit 1
    fi
    echo "✓ ${bin} is a static PIE"
done
