#!/usr/bin/env bash
# Checks for scripts/generate-sbom.sh.
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
SCRIPT="${ROOT}/scripts/generate-sbom.sh"
TMP=$(mktemp -d)
trap 'rm -rf "${TMP}"' EXIT

assert_eq() {
    local got=$1 expected=$2 msg=$3
    if [[ "${got}" != "${expected}" ]]; then
        echo "FAIL: ${msg}" >&2
        echo "  got:      ${got}" >&2
        echo "  expected: ${expected}" >&2
        exit 1
    fi
    echo "ok: ${msg}"
}

assert_ok() {
    local msg=$1
    echo "ok: ${msg}"
}

fail() {
    echo "FAIL: $1" >&2
    exit 1
}

# Every tool must declare SBOM_LIBS (empty is allowed).
while IFS= read -r mk; do
    if ! grep -q '^SBOM_LIBS *:=' "${mk}"; then
        fail "${mk} is missing SBOM_LIBS"
    fi
done < <(find "${ROOT}/tools" -mindepth 2 -maxdepth 2 -name versions.mk | sort)
assert_ok "every tools/*/versions.mk defines SBOM_LIBS"

openssl_ver=$(sed -n 's/^OPENSSL_VERSION := //p' "${ROOT}/deps/versions.mk")
nghttp2_ver=$(sed -n 's/^NGHTTP2_VERSION := //p' "${ROOT}/deps/versions.mk")
[[ -n "${openssl_ver}" && -n "${nghttp2_ver}" ]] || fail "could not read pinned library versions"

"${SCRIPT}" --tag v0000.00.0 --out-dir "${TMP}/one" curl-amd64 xxd-amd64 mtr-packet-amd64 magic.mgc-arm64

curl_sbom="${TMP}/one/curl-amd64.spdx.json"
xxd_sbom="${TMP}/one/xxd-amd64.spdx.json"
packet_sbom="${TMP}/one/mtr-packet-amd64.spdx.json"
magic_sbom="${TMP}/one/magic.mgc-arm64.spdx.json"

python3 - "${curl_sbom}" "${openssl_ver}" "${nghttp2_ver}" <<'PY'
import json, sys
doc = json.load(open(sys.argv[1]))
assert doc["spdxVersion"] == "SPDX-2.3", doc["spdxVersion"]
assert doc["name"] == "curl-amd64"
names = {p["name"]: p for p in doc["packages"]}
assert "curl-amd64" in names
assert names["openssl"]["versionInfo"] == sys.argv[2], names["openssl"]
assert names["nghttp2"]["versionInfo"] == sys.argv[3], names["nghttp2"]
assert "zlib" in names
assert "zstd" in names
assert doc["documentNamespace"].endswith("/v0000.00.0/curl-amd64"), doc["documentNamespace"]
rels = {(r["spdxElementId"], r["relationshipType"], r["relatedSpdxElement"]) for r in doc["relationships"]}
assert ("SPDXRef-DOCUMENT", "DESCRIBES", "SPDXRef-Package-curl-amd64") in rels
assert ("SPDXRef-Package-curl-amd64", "DEPENDS_ON", "SPDXRef-Package-openssl") in rels
PY
assert_ok "curl-amd64 SBOM lists OpenSSL ${openssl_ver}, nghttp2 ${nghttp2_ver}, and zstd; namespace carries the tag"

python3 - "${xxd_sbom}" <<'PY'
import json, sys
doc = json.load(open(sys.argv[1]))
names = {p["name"] for p in doc["packages"]}
assert names == {"xxd-amd64"}, names
assert all(r["relationshipType"] != "DEPENDS_ON" for r in doc["relationships"])
PY
assert_ok "xxd-amd64 SBOM does not contain OpenSSL"

python3 - "${packet_sbom}" <<'PY'
import json, sys
doc = json.load(open(sys.argv[1]))
names = {p["name"] for p in doc["packages"]}
assert names == {"mtr-packet-amd64"}, names
assert "ncurses" not in names
PY
assert_ok "mtr-packet-amd64 SBOM does not list ncurses"

python3 - "${magic_sbom}" <<'PY'
import json, sys
doc = json.load(open(sys.argv[1]))
names = {p["name"] for p in doc["packages"]}
assert names == {"magic.mgc-arm64"}, names
assert "zlib" not in names
PY
assert_ok "magic.mgc-arm64 SBOM does not list zlib"

read -r -a artifacts < <(make -s --no-print-directory -C "${ROOT}" print-artifacts)
# Some tools (iproute2, libcap, sysstat) ship no binary matching their own
# directory name, so "2 x (len(TOOLS) + fixed extras)" is not a valid
# formula in general. Check the invariant that actually has to hold instead:
# every basename appears for exactly amd64 and arm64, no more, no less.
mapfile -t basenames < <(printf '%s\n' "${artifacts[@]}" | sed -E 's/-(amd64|arm64)$//' | sort -u)
assert_eq "${#artifacts[@]}" "$(( 2 * ${#basenames[@]} ))" \
    "print-artifacts has exactly an amd64 and an arm64 entry for every basename"

"${SCRIPT}" --tag v0000.00.0 --out-dir "${TMP}/all" "${artifacts[@]}"
got=$(find "${TMP}/all" -name '*.spdx.json' | wc -l)
assert_eq "${got}" "${#artifacts[@]}" "generating every release artifact produces one file each"

python3 - "${TMP}/all" <<'PY'
import json, sys
from pathlib import Path

root = Path(sys.argv[1])

def names(artifact):
    doc = json.load(open(root / f"{artifact}.spdx.json"))
    return {p["name"] for p in doc["packages"]}

assert names("ip-amd64") == {"ip-amd64", "libcap"}, names("ip-amd64")
# ss is linked with global -lcap, but does not reference cap_* so --as-needed
# drops it. The SBOM must stay empty if that remains true.
assert names("ss-amd64") == {"ss-amd64"}, names("ss-amd64")
assert names("nmap-services-amd64") == {"nmap-services-amd64"}, names("nmap-services-amd64")
nmap = names("nmap-amd64")
assert {"nmap-amd64", "openssl", "zlib", "libpcap"} <= nmap, nmap
assert names("getcap-amd64") == {"getcap-amd64", "libcap"}, names("getcap-amd64")
assert names("sadc-amd64") == {"sadc-amd64"}, names("sadc-amd64")
assert names("less-amd64") == {"less-amd64", "ncurses"}, names("less-amd64")
assert names("nethogs-amd64") == {"nethogs-amd64", "libpcap", "ncurses"}, names("nethogs-amd64")
PY
assert_ok "new multi-name SBOM_LIBS overrides match the linked prefix libraries"

if "${SCRIPT}" --tag v0000.00.0 --out-dir "${TMP}/bad" not-an-artifact >/dev/null 2>"${TMP}/err"; then
    fail "expected malformed artifact name to fail"
fi
grep -q "must look like" "${TMP}/err" || fail "unexpected error for malformed artifact: $(cat "${TMP}/err")"
assert_ok "malformed artifact name is rejected"

if "${SCRIPT}" --tag v0000.00.0 --out-dir "${TMP}/bad" nosuchtool-amd64 >/dev/null 2>"${TMP}/err"; then
    fail "expected unknown tool to fail"
fi
grep -q "unknown artifact" "${TMP}/err" || fail "unexpected error for unknown tool: $(cat "${TMP}/err")"
assert_ok "unknown tool is rejected"

echo "generate-sbom tests passed"
