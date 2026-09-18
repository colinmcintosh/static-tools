#!/usr/bin/env bash
#
# Fail if a tool Dockerfile wgets a literal https:// URL.
# Source URLs belong in versions.mk and must be passed as
# ${*_SOURCE_URL} or ${*_URL} build-args (see deps/ and tools/curl).
#
# Usage:
#   scripts/assert-source-url-wired.sh [tools-dir]
#

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT=$(cd "${SCRIPT_DIR}/.." && pwd)
TOOLS_DIR=${1:-"${ROOT}/tools"}

if [[ ! -d "${TOOLS_DIR}" ]]; then
    echo "ERROR: tools directory not found: ${TOOLS_DIR}" >&2
    exit 1
fi

failed=0
while IFS= read -r df; do
    [[ -f "${df}" ]] || continue
    while IFS= read -r line; do
        # wget of a hardcoded URL; ${VAR} interpolations are allowed.
        if [[ "${line}" =~ wget[[:space:]]+.*\"https:// ]]; then
            echo "ERROR: ${df} wgets a literal URL:" >&2
            echo "  ${line}" >&2
            failed=1
        fi
    done < "${df}"
done < <(find "${TOOLS_DIR}" -mindepth 2 -maxdepth 2 -name Dockerfile | sort)

if ((failed)); then
    echo "Pass the URL as \${*_SOURCE_URL} or \${*_URL} from versions.mk." >&2
    exit 1
fi

echo "OK: no tool Dockerfile wgets a literal https:// URL"
