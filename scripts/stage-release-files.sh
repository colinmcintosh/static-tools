#!/usr/bin/env bash
#
# Stage the files a tool ships, by name, for upload as release artifacts.
#
# The Docker export copies all of /out/, which upstream build code can write
# to. Only the names tools/files.mk lists for TOOL are copied, so an extra
# file in the build output (say, another tool's curl-amd64) never reaches the
# release. Each file must be a regular file, and every file not in
# DATA_FILES must pass assert-static-elf.sh.
#
# Usage:
#   scripts/stage-release-files.sh TOOL ARCH SRC_DIR DEST_DIR
#
# Each file is copied from SRC_DIR to DEST_DIR/<name>-<ARCH>. DEST_DIR must
# not exist yet or must be empty.
#
# Environment:
#   ASSERT_STATIC_ELF   Static-PIE checker (default: scripts/assert-static-elf.sh)
#

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT=$(cd "${SCRIPT_DIR}/.." && pwd)
ASSERT_STATIC_ELF="${ASSERT_STATIC_ELF:-${SCRIPT_DIR}/assert-static-elf.sh}"

if [[ $# -ne 4 ]]; then
    echo "Usage: $0 TOOL ARCH SRC_DIR DEST_DIR" >&2
    exit 2
fi
tool=$1
arch=$2
src=$3
dest=$4

mapfile -t files < <(make -s --no-print-directory -C "${ROOT}" print-tool-files | awk -v tool="${tool}" '$1 == tool { print $2 }')
if ((${#files[@]} == 0)); then
    echo "::error::tools/files.mk lists no files for ${tool}" >&2
    exit 1
fi
read -r -a data_files <<< "$(make -s --no-print-directory -C "${ROOT}" print-data-files)"

mkdir -p "${dest}"
if [[ -n "$(find "${dest}" -mindepth 1 -maxdepth 1 -print -quit)" ]]; then
    echo "::error::${dest} must be empty" >&2
    exit 1
fi

bins=()
for name in "${files[@]}"; do
    if [[ -L "${src}/${name}" || ! -f "${src}/${name}" ]]; then
        echo "::error::${src}/${name} is missing or not a regular file" >&2
        exit 1
    fi
    cp "${src}/${name}" "${dest}/${name}-${arch}"
    if [[ " ${data_files[*]} " != *" ${name} "* ]]; then
        bins+=("${dest}/${name}-${arch}")
    fi
done
"${ASSERT_STATIC_ELF}" "${bins[@]}"

ls -la "${dest}"
