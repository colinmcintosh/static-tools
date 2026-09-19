#!/usr/bin/env bash
#
# Verify the pinned builder image, BUILDER_IMAGE@BUILDER_DIGEST in
# deps/versions.mk. Every deps and tool build runs in it, so it must be an
# image that .github/workflows/builder.yml built and attested on main, not
# one pushed from a branch or from anywhere else.
#
# With --lock, also check that the image's package list matches
# builder/apk-lock.txt. That reads the linux/amd64 image with docker.
#
# Requires the GitHub CLI. CI and release.yml run this before any build.
#
# Usage:
#   scripts/verify-builder-image.sh [--lock]

set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
REPO="${VERIFY_REPO:-colinmcintosh/static-tools}"

check_lock=false
case "$*" in
    "") ;;
    --lock) check_lock=true ;;
    *)
        echo "Usage: $0 [--lock]" >&2
        exit 2
        ;;
esac

image=$(sed -n 's/^BUILDER_IMAGE := //p' "${ROOT}/deps/versions.mk")
digest=$(sed -n 's/^BUILDER_DIGEST := //p' "${ROOT}/deps/versions.mk")
if [[ -z "${image}" || ! "${digest}" =~ ^sha256:[0-9a-f]{64}$ ]]; then
    echo "ERROR: could not read BUILDER_IMAGE and BUILDER_DIGEST from deps/versions.mk" >&2
    exit 1
fi

identity="https://github.com/${REPO}/.github/workflows/builder.yml@refs/heads/main"
echo "Image:         ${image}@${digest}"
echo "Cert identity: ${identity}"
if ! gh attestation verify "oci://${image}@${digest}" \
    --repo "${REPO}" \
    --cert-identity "${identity}" \
    --source-ref refs/heads/main \
    --deny-self-hosted-runners; then
    echo "ERROR: ${digest} has no attestation from builder.yml on main. Pin a digest that builder.yml published from main." >&2
    exit 1
fi
echo "✓ builder.yml on main built and attested ${digest}"

if [[ "${check_lock}" == true ]]; then
    if ! docker run --rm --platform linux/amd64 "${image}@${digest}" \
        cat /etc/static-tools-builder-packages.txt |
        diff -u "${ROOT}/builder/apk-lock.txt" -; then
        echo "ERROR: builder/apk-lock.txt does not match the packages in ${image}@${digest}" >&2
        exit 1
    fi
    echo "✓ builder/apk-lock.txt matches the image"
fi
