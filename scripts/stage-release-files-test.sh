#!/usr/bin/env bash
# Checks for scripts/stage-release-files.sh. Uses a stub static-PIE checker so
# the test needs no built binaries.
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
SCRIPT="${ROOT}/scripts/stage-release-files.sh"
TMP=$(mktemp -d)
trap 'rm -rf "${TMP}"' EXIT

assert_ok() {
    echo "ok: $1"
}

fail() {
    echo "FAIL: $1" >&2
    exit 1
}

# names DIR: the file names in DIR, sorted, space-separated.
names() {
    find "$1" -mindepth 1 -maxdepth 1 -printf '%f ' | tr ' ' '\n' | sort | paste -sd' ' -
}

# Record which files the ELF check sees; fail when STUB_ELF_FAIL is set.
cat > "${TMP}/assert-static-elf" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$@" >> "${STUB_ELF_LOG}"
[[ -z "${STUB_ELF_FAIL:-}" ]]
EOF
chmod +x "${TMP}/assert-static-elf"
export ASSERT_STATIC_ELF="${TMP}/assert-static-elf"
export STUB_ELF_LOG="${TMP}/elf.log"

# out TOOL: a fake build output dir holding every file TOOL ships.
out() {
    local dir="${TMP}/out-$1"
    mkdir -p "${dir}"
    while read -r _ name; do
        echo "${name}" > "${dir}/${name}"
    done < <(make -s --no-print-directory -C "${ROOT}" print-tool-files | awk -v tool="$1" '$1 == tool')
    echo "${dir}"
}

src=$(out tree)
echo planted > "${src}/curl-amd64"
: > "${STUB_ELF_LOG}"
"${SCRIPT}" tree amd64 "${src}" "${TMP}/stage-tree" >/dev/null
[[ "$(names "${TMP}/stage-tree")" == "tree-amd64" ]] || fail "expected only tree-amd64, got: $(names "${TMP}/stage-tree")"
[[ "$(cat "${STUB_ELF_LOG}")" == "${TMP}/stage-tree/tree-amd64" ]] || fail "ELF check should see only the staged tree binary"
assert_ok "an extra name in the build output is not staged"

src=$(out mtr)
"${SCRIPT}" mtr arm64 "${src}" "${TMP}/stage-mtr" >/dev/null
[[ "$(names "${TMP}/stage-mtr")" == "mtr-arm64 mtr-packet-arm64" ]] || fail "mtr should stage mtr and mtr-packet"
assert_ok "multi-binary tool stages every binary with the arch suffix"

src=$(out file)
: > "${STUB_ELF_LOG}"
"${SCRIPT}" file amd64 "${src}" "${TMP}/stage-file" >/dev/null
[[ "$(names "${TMP}/stage-file")" == "file-amd64 magic.mgc-amd64" ]] || fail "file should stage file and magic.mgc"
[[ "$(cat "${STUB_ELF_LOG}")" == "${TMP}/stage-file/file-amd64" ]] || fail "ELF check should skip the magic.mgc data file"
assert_ok "data files are staged but not ELF-checked"

src=$(out jq)
rm "${src}/jq"
ln -s /etc/hostname "${src}/jq"
if "${SCRIPT}" jq amd64 "${src}" "${TMP}/stage-symlink" >/dev/null 2>&1; then
    fail "a symlink should fail"
fi
assert_ok "symlink fails"

src=$(out nmap)
rm "${src}/nmap-services"
if "${SCRIPT}" nmap amd64 "${src}" "${TMP}/stage-missing" >/dev/null 2>&1; then
    fail "a missing file should fail"
fi
assert_ok "missing file fails"

src=$(out curl)
mkdir -p "${TMP}/stage-stale"
echo old > "${TMP}/stage-stale/old-amd64"
if "${SCRIPT}" curl amd64 "${src}" "${TMP}/stage-stale" >/dev/null 2>&1; then
    fail "a non-empty destination should fail"
fi
assert_ok "non-empty destination fails"

if STUB_ELF_FAIL=1 "${SCRIPT}" curl amd64 "${src}" "${TMP}/stage-notelf" >/dev/null 2>&1; then
    fail "a failed static-PIE check should fail"
fi
assert_ok "failed static-PIE check fails"

if "${SCRIPT}" nosuchtool amd64 "${src}" "${TMP}/stage-unknown" >/dev/null 2>&1; then
    fail "a tool with no entry in tools/files.mk should fail"
fi
assert_ok "unknown tool fails"

echo "stage-release-files tests passed"
