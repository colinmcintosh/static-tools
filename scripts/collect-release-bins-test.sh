#!/usr/bin/env bash
# Checks for scripts/collect-release-bins.sh.
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
SCRIPT="${ROOT}/scripts/collect-release-bins.sh"
TMP=$(mktemp -d)
trap 'rm -rf "${TMP}"' EXIT

fail() {
    echo "FAIL: $1" >&2
    exit 1
}

# Lay out artifacts the way download-artifact does: one directory per build
# artifact (<tool>-<arch>), plus a deps prefix that must be ignored.
read -r -a expected < <(make -s --no-print-directory -C "${ROOT}" print-artifacts)
while read -r tool name; do
    for arch in amd64 arm64; do
        mkdir -p "${TMP}/artifacts/${tool}-${arch}"
        echo "${name}-${arch}" > "${TMP}/artifacts/${tool}-${arch}/${name}-${arch}"
    done
done < <(make -s --no-print-directory -C "${ROOT}" print-tool-files)
mkdir -p "${TMP}/artifacts/deps-prefix-amd64/bin"
echo x > "${TMP}/artifacts/deps-prefix-amd64/bin/tool-amd64"

mapfile -t got < <("${SCRIPT}" "${TMP}/artifacts" "${TMP}/ok")
[[ "${#got[@]}" -eq "${#expected[@]}" ]] || fail "expected ${#expected[@]} names, got ${#got[@]}"
[[ ! -e "${TMP}/ok/tool-amd64" ]] || fail "deps prefix file was collected"
echo "ok: complete artifact set is collected and deps prefix is ignored"

echo x > "${TMP}/artifacts/curl-amd64/extra-amd64"
if "${SCRIPT}" "${TMP}/artifacts" "${TMP}/extra" >/dev/null 2>&1; then
    fail "expected an unlisted binary to fail"
fi
rm "${TMP}/artifacts/curl-amd64/extra-amd64"
echo "ok: unlisted binary is rejected"

# A compromised tree build could drop curl-amd64 into its own artifact.
echo planted > "${TMP}/artifacts/tree-amd64/curl-amd64"
if "${SCRIPT}" "${TMP}/artifacts" "${TMP}/duplicate" >/dev/null 2>&1; then
    fail "expected a name in two artifacts to fail"
fi
rm "${TMP}/artifacts/tree-amd64/curl-amd64"
echo "ok: a name in two artifacts is rejected"

mkdir -p "${TMP}/stale"
echo x > "${TMP}/stale/old-amd64"
if "${SCRIPT}" "${TMP}/artifacts" "${TMP}/stale" >/dev/null 2>&1; then
    fail "expected a non-empty destination to fail"
fi
echo "ok: non-empty destination is rejected"

rm "${TMP}/artifacts/curl-arm64/curl-arm64"
if "${SCRIPT}" "${TMP}/artifacts" "${TMP}/missing" >/dev/null 2>&1; then
    fail "expected a missing binary to fail"
fi
echo "ok: missing binary is rejected"

echo "collect-release-bins tests passed"
