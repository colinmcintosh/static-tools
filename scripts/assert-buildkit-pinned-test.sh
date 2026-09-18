#!/usr/bin/env bash
# Checks for scripts/assert-buildkit-pinned.sh.
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
SCRIPT="${ROOT}/scripts/assert-buildkit-pinned.sh"
TMP=$(mktemp -d)
trap 'rm -rf "${TMP}"' EXIT

PIN_A="moby/buildkit:v0.32.2@sha256:$(printf 'a%.0s' {1..64})"
PIN_B="moby/buildkit:v0.32.2@sha256:$(printf 'b%.0s' {1..64})"

assert_ok() {
    echo "ok: $1"
}

fail() {
    echo "FAIL: $1" >&2
    exit 1
}

# fixture NAME PIN_FOR_ci PIN_FOR_release [unpinned-step] [syntax]
fixture() {
    local dir="${TMP}/$1"
    mkdir -p "${dir}/.github/workflows" "${dir}/tools/curl"
    printf 'ARG BUILDER_IMAGE\n' > "${dir}/tools/curl/Dockerfile"
    local wf pin
    for wf in ci release; do
        if [[ "${wf}" == ci ]]; then pin=$2; else pin=$3; fi
        cat > "${dir}/.github/workflows/${wf}.yml" <<EOF
env:
  BUILDKIT_IMAGE: ${pin}
jobs:
  build:
    steps:
      - uses: docker/setup-buildx-action@37fe631027851001ddb9b187196cc803df7f5f0e # v4.3.0
        with:
          driver-opts: image=\${{ env.BUILDKIT_IMAGE }}
EOF
    done
    if [[ "${4:-}" == unpinned-step ]]; then
        echo '      - uses: docker/setup-buildx-action@37fe631027851001ddb9b187196cc803df7f5f0e # v4.3.0' \
            >> "${dir}/.github/workflows/release.yml"
    fi
    if [[ "${5:-}" == syntax ]]; then
        printf '# syntax=docker/dockerfile:1.7\n\nARG BUILDER_IMAGE\n' > "${dir}/tools/curl/Dockerfile"
    fi
    echo "${dir}"
}

if ! "${SCRIPT}" "$(fixture ok "${PIN_A}" "${PIN_A}")" >/dev/null; then
    fail "matching digest pins should pass"
fi
assert_ok "matching digest pins pass"

if "${SCRIPT}" "$(fixture tag moby/buildkit:buildx-stable-1 moby/buildkit:buildx-stable-1)" 2>/dev/null; then
    fail "a tag-only BuildKit image should fail"
fi
assert_ok "tag-only BuildKit image fails"

if "${SCRIPT}" "$(fixture differ "${PIN_A}" "${PIN_B}")" 2>/dev/null; then
    fail "different pins across workflows should fail"
fi
assert_ok "different pins across workflows fail"

if "${SCRIPT}" "$(fixture step "${PIN_A}" "${PIN_A}" unpinned-step)" 2>/dev/null; then
    fail "a setup-buildx step without driver-opts should fail"
fi
assert_ok "setup-buildx step without driver-opts fails"

if "${SCRIPT}" "$(fixture syntax "${PIN_A}" "${PIN_A}" "" syntax)" 2>/dev/null; then
    fail "a # syntax= line should fail"
fi
assert_ok "# syntax= line fails"

# The real tree must currently pass (this is the regression check).
if ! "${SCRIPT}" >/dev/null; then
    fail "repository workflows must pin BuildKit and Dockerfiles must not set # syntax="
fi
assert_ok "repository passes"
