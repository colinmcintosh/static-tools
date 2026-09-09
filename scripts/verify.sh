#!/usr/bin/env bash
#
# Verify GitHub Artifact Attestations for static-tools release artifacts.
#
# Requires the GitHub CLI (https://cli.github.com/). This script does not
# download or bootstrap any verifier binary.
#
# Usage:
#   ./scripts/verify.sh <artifact> [artifact...]
#
# Examples:
#   ./scripts/verify.sh curl-amd64
#   ./scripts/verify.sh curl-amd64 curl-arm64
#

set -euo pipefail

REPO="${VERIFY_REPO:-colinmcintosh/static-tools}"
SIGNER_WORKFLOW="${VERIFY_SIGNER_WORKFLOW:-colinmcintosh/static-tools/.github/workflows/attest.yml}"

usage() {
    echo "Usage: $0 <artifact> [artifact...]"
    echo ""
    echo "Verify SLSA build provenance with:"
    echo "  gh attestation verify <artifact> --repo ${REPO} --signer-workflow ${SIGNER_WORKFLOW}"
    echo ""
    echo "Requires the GitHub CLI: https://cli.github.com/"
    exit 1
}

if ! command -v gh >/dev/null 2>&1; then
    echo "ERROR: GitHub CLI (gh) is required. Install it from https://cli.github.com/" >&2
    exit 1
fi

if [[ $# -lt 1 ]]; then
    usage
fi

for artifact in "$@"; do
    if [[ ! -e "${artifact}" ]]; then
        echo "ERROR: Artifact not found: ${artifact}" >&2
        exit 1
    fi
    echo "Verifying ${artifact} (--signer-workflow ${SIGNER_WORKFLOW})"
    gh attestation verify "${artifact}" \
        --repo "${REPO}" \
        --signer-workflow "${SIGNER_WORKFLOW}"
done
