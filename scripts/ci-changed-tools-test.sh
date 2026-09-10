#!/usr/bin/env bash
# Path-mapping checks for scripts/ci-changed-tools.sh.
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
SCRIPT="${ROOT}/scripts/ci-changed-tools.sh"
TMP=$(mktemp -d)
trap 'rm -rf "${TMP}"' EXIT

git_init_fixture() {
    git init -q
    git config user.email test@example.com
    git config user.name test
    git config commit.gpgsign false
    mkdir -p tools/curl tools/wget deps scripts .github/workflows docs
    printf 'tool\n' > tools/curl/Dockerfile
    printf 'tool\n' > tools/wget/Dockerfile
    printf 'deps\n' > deps/Dockerfile
    printf 'make\n' > Makefile
    printf 'hadolint\n' > .hadolint.yaml
    printf 'script\n' > scripts/foo.sh
    printf 'ci\n' > .github/workflows/ci.yml
    printf 'readme\n' > README.md
    printf 'docs\n' > docs/SLSA.md
    cp "${SCRIPT}" scripts/ci-changed-tools.sh
    chmod +x scripts/ci-changed-tools.sh
    git add -A
    git commit -qm init
}

assert_eq() {
    local got=$1 expected=$2 msg=$3
    if [[ "${got}" != "${expected}" ]]; then
        echo "FAIL: ${msg}" >&2
        echo "  got:      ${got}" >&2
        echo "  expected: ${expected}" >&2
        exit 1
    fi
    echo "ok: ${msg}"
}

ALL_TOOLS='["curl", "wget"]'

cd "${TMP}"
git_init_fixture
BASE=$(git rev-parse HEAD)

assert_eq "$(scripts/ci-changed-tools.sh --all)" "${ALL_TOOLS}" "--all lists every tool"

# Documentation-only changes must skip builds.
printf 'x\n' >> README.md
printf 'x\n' >> docs/SLSA.md
git add -A && git commit -qm docs
assert_eq "$(scripts/ci-changed-tools.sh "${BASE}" HEAD)" '[]' "docs-only skips builds"

# Empty range.
assert_eq "$(scripts/ci-changed-tools.sh HEAD HEAD)" '[]' "empty diff skips builds"

# One tool.
git reset -q --hard "${BASE}"
printf 'x\n' >> tools/curl/Dockerfile
git add -A && git commit -qm curl
assert_eq "$(scripts/ci-changed-tools.sh "${BASE}" HEAD)" '["curl"]' "tools/curl rebuilds curl only"

# Shared deps rebuild everything.
git reset -q --hard "${BASE}"
printf 'x\n' >> deps/Dockerfile
git add -A && git commit -qm deps
assert_eq "$(scripts/ci-changed-tools.sh "${BASE}" HEAD)" "${ALL_TOOLS}" "deps rebuilds all tools"

# Infrastructure paths rebuild everything.
for spec in \
    "Makefile:Makefile" \
    ".hadolint.yaml:.hadolint.yaml" \
    "scripts/foo.sh:scripts" \
    ".github/workflows/ci.yml:workflows"
do
    file=${spec%%:*}
    label=${spec##*:}
    git reset -q --hard "${BASE}"
    printf 'x\n' >> "${file}"
    git add -A && git commit -qm "${label}"
    assert_eq "$(scripts/ci-changed-tools.sh "${BASE}" HEAD)" "${ALL_TOOLS}" "${file} rebuilds all tools"
done

echo "✓ ci-changed-tools path mapping"
