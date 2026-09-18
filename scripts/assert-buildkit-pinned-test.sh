#!/usr/bin/env bash
# Checks for scripts/assert-buildkit-pinned.sh.
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
SCRIPT="${ROOT}/scripts/assert-buildkit-pinned.sh"
TMP=$(mktemp -d)
trap 'rm -rf "${TMP}"' EXIT

PIN_A="moby/buildkit:v0.32.2@sha256:$(printf 'a%.0s' {1..64})"
PIN_B="moby/buildkit:v0.32.2@sha256:$(printf 'b%.0s' {1..64})"
USES='        uses: docker/setup-buildx-action@37fe631027851001ddb9b187196cc803df7f5f0e # v4.3.0'
# shellcheck disable=SC2016 # ${{ }} is a literal Actions expression
IMAGE='          driver-opts: image=${{ env.BUILDKIT_IMAGE }}'
DRIVER='          driver: docker-container'
PINNED_STEP="      - name: Set up Docker Buildx
${USES}
        with:
${DRIVER}
${IMAGE}"

assert_ok() {
    echo "ok: $1"
}

fail() {
    echo "FAIL: $1" >&2
    exit 1
}

# repo NAME: a fixture repository with one clean Dockerfile. Prints its path.
repo() {
    mkdir -p "${TMP}/$1/.github/workflows" "${TMP}/$1/tools/curl"
    printf 'ARG BUILDER_IMAGE\n' > "${TMP}/$1/tools/curl/Dockerfile"
    echo "${TMP}/$1"
}

# workflow REPO FILE PIN STEPS: a workflow pinning PIN at the top level,
# with STEPS as the steps of its only job.
workflow() {
    cat > "$1/.github/workflows/$2" <<EOF
env:
  BUILDKIT_IMAGE: $3
jobs:
  build:
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
$4
      - run: make build
EOF
}

expect_pass() {
    if ! "${SCRIPT}" "$1" >/dev/null; then
        fail "$2 should pass"
    fi
    assert_ok "$2 passes"
}

expect_fail() {
    if "${SCRIPT}" "$1" >/dev/null 2>&1; then
        fail "$2 should fail"
    fi
    assert_ok "$2 fails"
}

r=$(repo ok)
workflow "${r}" ci.yml "${PIN_A}" "${PINNED_STEP}"
workflow "${r}" release.yml "${PIN_A}" "${PINNED_STEP}"
expect_pass "${r}" "matching digest pins"

r=$(repo tag)
workflow "${r}" ci.yml moby/buildkit:buildx-stable-1 "${PINNED_STEP}"
expect_fail "${r}" "a tag-only BuildKit image"

r=$(repo differ)
workflow "${r}" ci.yml "${PIN_A}" "${PINNED_STEP}"
workflow "${r}" release.yml "${PIN_B}" "${PINNED_STEP}"
expect_fail "${r}" "different pins across workflows"

r=$(repo no-driver)
workflow "${r}" ci.yml "${PIN_A}" "      - name: Set up Docker Buildx
${USES}
        with:
${IMAGE}"
expect_fail "${r}" "a setup-buildx step without driver: docker-container"

r=$(repo comment)
workflow "${r}" ci.yml "${PIN_A}" "      - name: Set up Docker Buildx
${USES}
        with:
${DRIVER}
          # driver-opts: image=\${{ env.BUILDKIT_IMAGE }}"
expect_fail "${r}" "driver-opts only in a comment"

r=$(repo other-step)
workflow "${r}" ci.yml "${PIN_A}" "      - name: Set up Docker Buildx
${USES}
      - name: Unrelated step
        uses: actions/cache@55cc8345863c7cc4c66a329aec7e433d2d1c52a9 # v6.1.0
        with:
${DRIVER}
${IMAGE}"
expect_fail "${r}" "driver settings in a different step"

r=$(repo override)
workflow "${r}" ci.yml "${PIN_A}" "${PINNED_STEP}
    env:
      BUILDKIT_IMAGE: moby/buildkit:latest"
expect_fail "${r}" "a job-level BUILDKIT_IMAGE override"

r=$(repo syntax)
workflow "${r}" ci.yml "${PIN_A}" "${PINNED_STEP}"
printf '# syntax=docker/dockerfile:1.7\n\nARG BUILDER_IMAGE\n' > "${r}/tools/curl/Dockerfile"
expect_fail "${r}" "a # syntax= line"

# The real tree must currently pass (this is the regression check).
expect_pass "" "the repository"
