#!/usr/bin/env bash
#
# Stage the files a tool ships, by name, for upload as release artifacts.
#
# The Docker export copies all of /out/, which upstream build code can write
# to. Only the names listed here are copied, so an extra file in the build
# output (say, another tool's curl-amd64) never reaches the release. Each
# file must be a regular file; binaries must pass assert-static-elf.sh.
#
# Usage:
#   scripts/stage-release-files.sh --list TOOL
#   scripts/stage-release-files.sh TOOL ARCH SRC_DIR DEST_DIR
#
# --list prints the names TOOL ships, one per line (no -<arch> suffix).
# Otherwise each name is copied from SRC_DIR to DEST_DIR/<name>-<ARCH>.
# DEST_DIR must not exist yet or must be empty.
#
# Environment:
#   ASSERT_STATIC_ELF   Static-PIE checker (default: scripts/assert-static-elf.sh)
#

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ASSERT_STATIC_ELF="${ASSERT_STATIC_ELF:-${SCRIPT_DIR}/assert-static-elf.sh}"

usage() {
    echo "Usage: $0 --list TOOL" >&2
    echo "       $0 TOOL ARCH SRC_DIR DEST_DIR" >&2
    exit 2
}

# Sets bins (static PIE executables) and data (other shipped files) for $1.
# Keep in sync with EXTRA_ARTIFACTS in the root Makefile; the test checks it.
tool_files() {
    bins=()
    data=()
    case "$1" in
        mtr) bins=(mtr mtr-packet) ;;
        file) bins=(file); data=(magic.mgc) ;;
        iproute2) bins=(ip ss) ;;
        sysstat) bins=(mpstat iostat pidstat sar sadc) ;;
        libcap) bins=(getcap setcap) ;;
        nmap) bins=(nmap); data=(nmap-services) ;;
        *) bins=("$1") ;;
    esac
}

if [[ "${1:-}" == "--list" ]]; then
    [[ $# -eq 2 ]] || usage
    tool_files "$2"
    printf '%s\n' "${bins[@]}" "${data[@]}"
    exit 0
fi

[[ $# -eq 4 ]] || usage
tool=$1
arch=$2
src=$3
dest=$4

tool_files "${tool}"
mkdir -p "${dest}"
if [[ -n "$(find "${dest}" -mindepth 1 -maxdepth 1 -print -quit)" ]]; then
    echo "::error::${dest} must be empty" >&2
    exit 1
fi

for name in "${bins[@]}" "${data[@]}"; do
    if [[ -L "${src}/${name}" || ! -f "${src}/${name}" ]]; then
        echo "::error::${src}/${name} is missing or not a regular file" >&2
        exit 1
    fi
    cp "${src}/${name}" "${dest}/${name}-${arch}"
done

staged_bins=()
for name in "${bins[@]}"; do
    staged_bins+=("${dest}/${name}-${arch}")
done
"${ASSERT_STATIC_ELF}" "${staged_bins[@]}"

ls -la "${dest}"
