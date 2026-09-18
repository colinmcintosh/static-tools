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
# artifact, plus a deps prefix that must be ignored.
read -r -a expected < <(make -s --no-print-directory -C "${ROOT}" print-artifacts)
for name in "${expected[@]}"; do
    arch=${name##*-}
    bundle=${name%-*}
    case "${bundle}" in
        mtr-packet) bundle="mtr" ;;
        magic.mgc) bundle="file" ;;
        nmap-services) bundle="nmap" ;;
        ip|ss) bundle="iproute2" ;;
        getcap|setcap) bundle="libcap" ;;
        mpstat|iostat|pidstat|sar|sadc) bundle="sysstat" ;;
    esac
    mkdir -p "${TMP}/artifacts/${bundle}-${arch}"
    echo "${name}" > "${TMP}/artifacts/${bundle}-${arch}/${name}"
done
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

rm "${TMP}/artifacts/curl-arm64/curl-arm64"
if "${SCRIPT}" "${TMP}/artifacts" "${TMP}/missing" >/dev/null 2>&1; then
    fail "expected a missing binary to fail"
fi
echo "ok: missing binary is rejected"

echo "collect-release-bins tests passed"
