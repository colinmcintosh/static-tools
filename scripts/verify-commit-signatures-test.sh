#!/usr/bin/env bash
# Fail-closed and allowlist checks for scripts/verify-commit-signatures.sh.
# Uses a stub git/curl/gpg so the test does not need network or real keys.
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
SCRIPT="${ROOT}/scripts/verify-commit-signatures.sh"
TMP=$(mktemp -d)
trap 'rm -rf "${TMP}"' EXIT

cat > "${TMP}/allowed.txt" <<'EOF'
# comment
968479A1AFF927E37D1A566BB5690EEEBB952194
A4B4FDDC55108DD6AF1A88E125C4F1CA7EE971E0
EOF

mkdir -p "${TMP}/bin"
cat > "${TMP}/bin/git" <<'EOF'
#!/usr/bin/env bash
if [[ "$1" == "log" ]]; then
    cat "${GIT_LOG_FIXTURE}"
    exit 0
fi
echo "unexpected git $*" >&2
exit 2
EOF
cat > "${TMP}/bin/curl" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
cat > "${TMP}/bin/gpg" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod +x "${TMP}/bin/git" "${TMP}/bin/curl" "${TMP}/bin/gpg"

export PATH="${TMP}/bin:${PATH}"
export ALLOWED_SIGNING_KEYS="${TMP}/allowed.txt"
export GIT_LOG_FIXTURE="${TMP}/log"

run_check() {
    "${SCRIPT}" HEAD
}

expect_pass() {
    local msg=$1
    if ! run_check; then
        echo "FAIL: expected pass: ${msg}" >&2
        exit 1
    fi
    echo "ok: pass ${msg}"
}

expect_fail() {
    local msg=$1
    if run_check; then
        echo "FAIL: expected fail: ${msg}" >&2
        exit 1
    fi
    echo "ok: fail ${msg}"
}

printf 'abc\tG\tA4B4FDDC55108DD6AF1A88E125C4F1CA7EE971E0\n' > "${TMP}/log"
expect_pass "G + allowlisted fingerprint"

printf 'abc\tU\t968479A1AFF927E37D1A566BB5690EEEBB952194\n' > "${TMP}/log"
expect_pass "U + allowlisted fingerprint"

printf 'abc\tG\ta4b4fddc55108dd6af1a88e125c4f1ca7ee971e0\n' > "${TMP}/log"
expect_pass "G + allowlisted fingerprint in lower case"

printf 'abc\tG\t25C4F1CA7EE971E0\n' > "${TMP}/log"
expect_fail "G + 16-char key ID of an allowlisted fingerprint"

printf 'abc\tG\t0000FDDC55108DD6AF1A88E125C4F1CA7EE971E0\n' > "${TMP}/log"
expect_fail "G + fingerprint sharing an allowlisted key ID"

printf 'abc\tG\tDEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEF\n' > "${TMP}/log"
expect_fail "G + unknown fingerprint"

printf 'abc\tG\t\n' > "${TMP}/log"
expect_fail "G + empty fingerprint"

for status in N B E X Y R Z; do
    printf 'abc\t%s\tA4B4FDDC55108DD6AF1A88E125C4F1CA7EE971E0\n' "${status}" > "${TMP}/log"
    expect_fail "status ${status}"
done

cat > "${TMP}/bad.txt" <<'EOF'
not-a-fingerprint
EOF
ALLOWED_SIGNING_KEYS="${TMP}/bad.txt"
export ALLOWED_SIGNING_KEYS
expect_fail "invalid allowlist file"

echo "✓ verify-commit-signatures fail-closed checks"
