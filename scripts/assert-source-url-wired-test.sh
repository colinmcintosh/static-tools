#!/usr/bin/env bash
# Checks for scripts/assert-source-url-wired.sh.
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
SCRIPT="${ROOT}/scripts/assert-source-url-wired.sh"
TMP=$(mktemp -d)
trap 'rm -rf "${TMP}"' EXIT

assert_ok() {
    echo "ok: $1"
}

fail() {
    echo "FAIL: $1" >&2
    exit 1
}

mkdir -p "${TMP}/ok/curl" "${TMP}/bad/curl"

cat > "${TMP}/ok/curl/Dockerfile" <<'EOF'
ARG CURL_SOURCE_URL
RUN wget -q "${CURL_SOURCE_URL}" -O curl.tar.gz
EOF

cat > "${TMP}/bad/curl/Dockerfile" <<'EOF'
ARG CURL_VERSION
RUN wget -q "https://curl.se/download/curl-${CURL_VERSION}.tar.gz" -O curl.tar.gz
EOF

if ! "${SCRIPT}" "${TMP}/ok"; then
    fail "wired URL should pass"
fi
assert_ok "wired \${CURL_SOURCE_URL} passes"

if "${SCRIPT}" "${TMP}/bad"; then
    fail "literal https URL should fail"
fi
assert_ok "literal https URL fails"

# The real tree must currently pass (this is the regression check).
if ! "${SCRIPT}"; then
    fail "repository tools/ Dockerfiles must not wget literal URLs"
fi
assert_ok "repository tools/ pass"
