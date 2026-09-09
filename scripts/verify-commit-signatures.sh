#!/usr/bin/env bash
#
# Verify that every commit in a revision range carries an acceptable signature.
#
# Trusted keys are fetched from GitHub: the web-flow key, which signs commits
# created through the GitHub UI and API, and the repository owner's key.
#
# Usage:
#   scripts/verify-commit-signatures.sh <rev-range>
#
# Examples:
#   scripts/verify-commit-signatures.sh origin/main..HEAD
#   scripts/verify-commit-signatures.sh "${SHA}^!"
#
# Environment:
#   KEY_OWNER   GitHub account whose public keys are trusted
#               (default: colinmcintosh)
#

set -euo pipefail

KEY_OWNER="${KEY_OWNER:-colinmcintosh}"

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <rev-range>" >&2
    exit 2
fi

range=$1

echo "Importing GitHub web-flow and ${KEY_OWNER} signing keys..."
curl -fsSL https://github.com/web-flow.gpg | gpg --import
curl -fsSL "https://github.com/${KEY_OWNER}.gpg" | gpg --import

echo "Checking commit signatures in ${range}..."
failed=0
while IFS=$'\t' read -r hash status; do
    [ -z "${hash}" ] && continue
    case "${status}" in
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
    esac
done < <(git log --format="%H%x09%G?" "${range}")

if [ "${failed}" -ne 0 ]; then
    exit 1
fi
echo "✓ Commit signatures verified for ${range}"
