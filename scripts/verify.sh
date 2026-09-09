#!/usr/bin/env bash
#
# Verify GitHub Artifact Attestations for static-tools release artifacts.
#
# The release tag is required. `--signer-workflow` matches only the workflow
# path and ignores the ref the workflow ran from, so it would accept an
# attestation minted from any branch. `--cert-identity` pins both.
#
# Requires the GitHub CLI (https://cli.github.com/). This script does not
# download or bootstrap any verifier binary.
#
# Usage:
#   ./scripts/verify.sh <tag> <artifact> [artifact...]
#
# Examples:
#   ./scripts/verify.sh v2026.09.3 curl-amd64
#   ./scripts/verify.sh v2026.09.3 curl-amd64 curl-arm64
#

set -euo pipefail

REPO="${VERIFY_REPO:-colinmcintosh/static-tools}"
SIGNER_WORKFLOW_PATH="${VERIFY_SIGNER_WORKFLOW_PATH:-.github/workflows/attest.yml}"

usage() {
    cat >&2 <<USAGE
Usage: $0 <tag> <artifact> [artifact...]

Verify SLSA build provenance, pinned to the release tag so that an attestation
produced from any other ref is rejected.

Examples:
  $0 v2026.09.3 curl-amd64
  $0 v2026.09.3 curl-amd64 curl-arm64

Requires the GitHub CLI: https://cli.github.com/
USAGE
    exit 1
}

if ! command -v gh >/dev/null 2>&1; then
    echo "ERROR: GitHub CLI (gh) is required. Install it from https://cli.github.com/" >&2
    exit 1
fi

if [[ $# -lt 2 ]]; then
    usage
fi

tag=$1
shift

if [[ "${tag}" != v* ]]; then
    echo "ERROR: first argument must be a release tag such as v2026.09.3, got '${tag}'" >&2
    usage
fi

cert_identity="https://github.com/${REPO}/${SIGNER_WORKFLOW_PATH}@refs/tags/${tag}"

echo "Repository:    ${REPO}"
echo "Cert identity: ${cert_identity}"
echo "Source ref:    refs/tags/${tag}"
echo ""

for artifact in "$@"; do
    if [[ ! -e "${artifact}" ]]; then
        echo "ERROR: Artifact not found: ${artifact}" >&2
        exit 1
    fi
    echo "Verifying ${artifact}..."
    gh attestation verify "${artifact}" \
        --repo "${REPO}" \
        --cert-identity "${cert_identity}" \
        --source-ref "refs/tags/${tag}" \
        --deny-self-hosted-runners
    echo "✓ ${artifact}"
done
