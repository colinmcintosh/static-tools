#!/usr/bin/env bash
#
# Verify that every commit in a revision range carries an acceptable signature.
#
# Accepts only git %G? statuses G (good, valid) and U (good, unknown validity).
# Everything else fails, including expired signatures (X), expired keys (Y),
# revoked keys (R), and any status code a future git release might add.
#
# Each accepted signature's fingerprint (%GF) must appear in
# scripts/allowed-signing-keys.txt. Keys are still imported from GitHub so
# git can verify the cryptographic signature; the allowlist is the trust
# anchor, not the live keyring.
#
# Usage:
#   scripts/verify-commit-signatures.sh <rev-range>
#
# Examples:
#   scripts/verify-commit-signatures.sh origin/main..HEAD
#   scripts/verify-commit-signatures.sh "${SHA}^!"
#
# Environment:
#   KEY_OWNER              GitHub account whose public keys are imported
#                          (default: colinmcintosh)
#   ALLOWED_SIGNING_KEYS   Override path to the fingerprint allowlist
#

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
KEY_OWNER="${KEY_OWNER:-colinmcintosh}"
KEYS_FILE="${ALLOWED_SIGNING_KEYS:-${SCRIPT_DIR}/allowed-signing-keys.txt}"

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <rev-range>" >&2
    exit 2
fi

range=$1

normalize_fp() {
    printf '%s' "$1" | tr '[:lower:]' '[:upper:]' | tr -d '[:space:]'
}

load_allowed_fingerprints() {
    if [[ ! -f "${KEYS_FILE}" ]]; then
        echo "ERROR: allowed signing keys file not found: ${KEYS_FILE}" >&2
        exit 1
    fi

    allowed_fps=()
    local line normalized
    while IFS= read -r line || [[ -n "${line}" ]]; do
        line="${line%%#*}"
        normalized="$(normalize_fp "${line}")"
        [[ -z "${normalized}" ]] && continue
        if [[ ! "${normalized}" =~ ^[0-9A-F]{40}$ ]]; then
            echo "ERROR: invalid fingerprint in ${KEYS_FILE}: ${line}" >&2
            exit 1
        fi
        allowed_fps+=("${normalized}")
    done < "${KEYS_FILE}"

    if ((${#allowed_fps[@]} == 0)); then
        echo "ERROR: ${KEYS_FILE} contains no fingerprints" >&2
        exit 1
    fi
}

fingerprint_allowed() {
    local fp allowed
    fp="$(normalize_fp "$1")"
    # git %GF is 40 hex chars; accept a 16+ char suffix so a short key ID
    # still matches a committed full fingerprint, but reject anything shorter.
    if ((${#fp} < 16)); then
        return 1
    fi
    for allowed in "${allowed_fps[@]}"; do
        if [[ "${fp}" == "${allowed}" || "${allowed}" == *"${fp}" ]]; then
            return 0
        fi
    done
    return 1
}

load_allowed_fingerprints

echo "Importing GitHub web-flow and ${KEY_OWNER} signing keys..."
curl -fsSL https://github.com/web-flow.gpg | gpg --import
curl -fsSL "https://github.com/${KEY_OWNER}.gpg" | gpg --import

echo "Checking commit signatures in ${range}..."
failed=0
while IFS=$'\t' read -r hash status fp; do
    [ -z "${hash}" ] && continue
    case "${status}" in
        G|U)
            if ! fingerprint_allowed "${fp}"; then
                echo "::error::Signature fingerprint '${fp}' is not in the allowlist: ${hash}"
                failed=1
            fi
            ;;
        N)
            echo "::error::Unsigned commit: ${hash}"
            failed=1
            ;;
        B)
            echo "::error::Bad signature: ${hash}"
            failed=1
            ;;
        E)
            echo "::error::Cannot check signature (missing key): ${hash}"
            failed=1
            ;;
        X)
            echo "::error::Expired signature: ${hash}"
            failed=1
            ;;
        Y)
            echo "::error::Signature made by expired key: ${hash}"
            failed=1
            ;;
        R)
            echo "::error::Signature made by revoked key: ${hash}"
            failed=1
            ;;
        *)
            echo "::error::Unacceptable signature status '${status}' on ${hash}"
            failed=1
            ;;
    esac
done < <(git log --format="%H%x09%G?%x09%GF" "${range}")

if [ "${failed}" -ne 0 ]; then
    exit 1
fi
echo "✓ Commit signatures verified for ${range}"
