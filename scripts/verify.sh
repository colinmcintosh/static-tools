#!/usr/bin/env bash
#
# Verify GitHub Artifact Attestations for static-tools release artifacts.
#
# The release tag is required. `--signer-workflow` matches only the workflow
# path and ignores the ref the workflow ran from, so it would accept an
# attestation minted from any branch. `--cert-identity` pins both.
#
# Set VERIFY_PREDICATE_TYPE to verify a different attestation predicate, for
# example https://spdx.dev/Document/v2.3 for the per-binary SBOM. Artifacts are
# verified in parallel (VERIFY_JOBS, default nproc).
#
# Requires the GitHub CLI (https://cli.github.com/). This script does not
# download or bootstrap any verifier binary.
#
# Usage:
#   ./scripts/verify.sh <tag> <artifact> [artifact...]
#
# Examples:
#   ./scripts/verify.sh v2026.09.3 curl-amd64
#   ./scripts/verify.sh v2026.09.3 curl-amd64 SHA256SUMS.txt
#

set -euo pipefail

REPO="${VERIFY_REPO:-colinmcintosh/static-tools}"
SIGNER_WORKFLOW_PATH="${VERIFY_SIGNER_WORKFLOW_PATH:-.github/workflows/attest.yml}"
PREDICATE_TYPE="${VERIFY_PREDICATE_TYPE:-}"
JOBS="${VERIFY_JOBS:-$(nproc 2>/dev/null || echo 4)}"

usage() {
    cat >&2 <<USAGE
Usage: $0 <tag> <artifact> [artifact...]

Verify SLSA build provenance, pinned to the release tag so that an attestation
produced from any other ref is rejected.

Examples:
  $0 v2026.09.3 curl-amd64
  $0 v2026.09.3 curl-amd64 SHA256SUMS.txt

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
echo "Predicate:     ${PREDICATE_TYPE:-SLSA provenance (gh default)}"
echo ""

for artifact in "$@"; do
    if [[ ! -e "${artifact}" ]]; then
        echo "ERROR: Artifact not found: ${artifact}" >&2
        exit 1
    fi
done

verify_one() {
    local artifact=$1 out
    local predicate_args=()
    if [[ -n "${PREDICATE_TYPE}" ]]; then
        predicate_args=(--predicate-type "${PREDICATE_TYPE}")
    fi
    # Buffer per artifact so parallel output does not interleave.
    if out=$(gh attestation verify "${artifact}" \
        ${predicate_args[@]+"${predicate_args[@]}"} \
        --repo "${REPO}" \
        --cert-identity "${cert_identity}" \
        --source-ref "refs/tags/${tag}" \
        --deny-self-hosted-runners 2>&1); then
        printf '%s\n✓ %s\n' "${out}" "${artifact}"
    else
        printf '%s\n✗ %s\n' "${out}" "${artifact}" >&2
        return 1
    fi
}
export -f verify_one
export REPO PREDICATE_TYPE cert_identity tag

# xargs exits non-zero if any invocation failed.
if ! printf '%s\0' "$@" | xargs -0 -n1 -P"${JOBS}" bash -c 'verify_one "$1"' _; then
    echo "ERROR: attestation verification failed" >&2
    exit 1
fi
