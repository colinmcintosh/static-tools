#!/usr/bin/env bash
# Fail-closed checks for scripts/verify-upstream-signatures.sh.
# Uses a throwaway GnuPG key so the test does not need network or real keys.
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
SCRIPT="${ROOT}/scripts/verify-upstream-signatures.sh"
TMP=$(mktemp -d)
trap 'rm -rf "${TMP}"' EXIT

assert_ok() {
    echo "ok: $1"
}

fail() {
    echo "FAIL: $1" >&2
    exit 1
}

GNUPGHOME="${TMP}/gnupg"
export GNUPGHOME
mkdir -m 700 "${GNUPGHOME}"
gpg --batch --pinentry-mode loopback --passphrase '' \
    --quick-generate-key 'static-tools-test <test@example.com>' default default never >/dev/null 2>&1

mkdir -p "${TMP}/keys" "${TMP}/repo/deps" "${TMP}/repo/tools/curl" "${TMP}/cache"
gpg --batch --armor --export 'static-tools-test' > "${TMP}/keys/curl.asc"
unset GNUPGHOME

printf 'hello signed tarball\n' > "${TMP}/cache/curl.tar"
SHA=$(sha256sum "${TMP}/cache/curl.tar" | awk '{print $1}')
GNUPGHOME="${TMP}/gnupg" gpg --batch --pinentry-mode loopback --passphrase '' \
    --armor --detach-sign --output "${TMP}/cache/curl.sig" "${TMP}/cache/curl.tar"

# Local HTTP-less test: point URLs at file:// of the cache copies.
# The script uses urllib, which understands file://.
TARBALL_URL="file://${TMP}/cache/curl.tar"
SIG_URL="file://${TMP}/cache/curl.sig"

cat > "${TMP}/repo/deps/versions.mk" <<EOF
ZLIB_VERSION := 1.0.0
ZLIB_URL := file://${TMP}/missing.tar
ZLIB_SHA256 := 00
EOF

cat > "${TMP}/repo/tools/curl/versions.mk" <<EOF
CURL_VERSION := 1.0.0
CURL_SOURCE_URL := ${TARBALL_URL}
CURL_SOURCE_SHA256 := ${SHA}
CURL_SOURCE_SIG_URL := ${SIG_URL}
CURL_SOURCE_KEY := curl
SBOM_LIBS :=
EOF

export ROOT="${TMP}/repo"
export KEYS_DIR="${TMP}/keys"
export CACHE_DIR="${TMP}/dl"

if ! "${SCRIPT}"; then
    fail "good signature and matching SHA256 should pass"
fi
assert_ok "good signature + SHA256 passes"

sed -i "s/${SHA}/deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef/" \
    "${TMP}/repo/tools/curl/versions.mk"
rm -rf "${TMP}/dl"
if "${SCRIPT}"; then
    fail "SHA256 mismatch should fail"
fi
assert_ok "SHA256 mismatch fails"

sed -i "s/deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef/${SHA}/" \
    "${TMP}/repo/tools/curl/versions.mk"
printf 'not a signature\n' > "${TMP}/cache/curl.sig"
rm -rf "${TMP}/dl"
if "${SCRIPT}"; then
    fail "bad signature should fail"
fi
assert_ok "bad signature fails"

rm -f "${TMP}/keys/curl.asc"
rm -rf "${TMP}/dl"
if "${SCRIPT}"; then
    fail "missing committed key should fail"
fi
assert_ok "missing committed key fails"
