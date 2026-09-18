#!/usr/bin/env bash
#
# Fail unless BuildKit is pinned by digest in every workflow that sets up
# Buildx, and no Dockerfile picks its own frontend.
#
# BuildKit runs every RUN step. Without a `# syntax=` line it also supplies
# the Dockerfile frontend, so one digest pins both. Each workflow defines
# BUILDKIT_IMAGE (moby/buildkit:<version>@sha256:<digest>) once, in its
# top-level env, and every docker/setup-buildx-action step sets both
#     driver: docker-container
#     driver-opts: image=${{ env.BUILDKIT_IMAGE }}
# The driver must be explicit: the docker driver ignores image=. All
# workflows must use the same pin.
#
# This reads lines, not YAML, but it is step-aware: both settings must sit
# inside the step that uses setup-buildx-action, and comments never count.
#
# Usage:
#   scripts/assert-buildkit-pinned.sh [repo-root]
#

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT=${1:-"$(cd "${SCRIPT_DIR}/.." && pwd)"}
cd "${ROOT}"

# Print how many steps in workflow $1 use setup-buildx-action. Exit non-zero
# if any of them does not set the driver and the pinned image.
check_buildx_steps() {
    # shellcheck disable=SC2016 # ${{ }} is a literal Actions expression
    awk '
        function finish() {
            if (buildx) {
                count++
                if (!driver) {
                    printf "ERROR: %s:%d: setup-buildx-action step does not set driver: docker-container\n", FILENAME, start > "/dev/stderr"
                    bad = 1
                }
                if (!image) {
                    printf "ERROR: %s:%d: setup-buildx-action step does not set driver-opts: image=${{ env.BUILDKIT_IMAGE }}\n", FILENAME, start > "/dev/stderr"
                    bad = 1
                }
            }
            in_item = buildx = driver = image = 0
        }
        /^[ \t]*(#|$)/ { next }
        {
            match($0, /^ */)
            indent = RLENGTH
            if (in_item && indent <= item_indent) finish()
            if (!in_item && $0 ~ /^ *- /) { in_item = 1; item_indent = indent; start = FNR }
            if (!in_item) next
            line = $0
            sub(/^ *(- +)?/, "", line)
            sub(/[ \t]+#.*$/, "", line)
            if (line ~ /^uses: *docker\/setup-buildx-action@/) buildx = 1
            else if (line == "driver: docker-container") driver = 1
            else if (line == "driver-opts: image=${{ env.BUILDKIT_IMAGE }}") image = 1
        }
        END { finish(); print count + 0; exit bad }
    ' "$1"
}

failed=0
pins=()
for wf in .github/workflows/*.yml; do
    if ! steps=$(check_buildx_steps "${wf}"); then
        failed=1
    fi
    ((steps > 0)) || continue
    # A job- or step-level env could override the top-level pin.
    defs=$(grep -cE '^[[:space:]]*BUILDKIT_IMAGE:' "${wf}" || true)
    pin=$(sed -n 's/^  BUILDKIT_IMAGE: *\([^ #]*\).*/\1/p' "${wf}")
    if ((defs != 1)) || [[ ! "${pin}" =~ ^moby/buildkit:v[0-9][0-9.]*@sha256:[0-9a-f]{64}$ ]]; then
        echo "ERROR: ${wf}: define BUILDKIT_IMAGE once, in the top-level env, as moby/buildkit:<version>@sha256:<digest> (found ${defs} definition(s); top-level value '${pin}')" >&2
        failed=1
    fi
    pins+=("${pin}")
done

if ((${#pins[@]} == 0)); then
    echo "ERROR: no workflow sets up Buildx" >&2
    failed=1
elif (($(printf '%s\n' "${pins[@]}" | sort -u | wc -l) > 1)); then
    echo "ERROR: BUILDKIT_IMAGE differs between workflows:" >&2
    printf '  %s\n' "${pins[@]}" | sort -u >&2
    failed=1
fi

while IFS= read -r df; do
    if grep -qiE '^#[[:space:]]*syntax[[:space:]]*=' "${df}"; then
        echo "ERROR: ${df}: remove the '# syntax=' line; builds use the pinned BuildKit's built-in frontend" >&2
        failed=1
    fi
done < <(find . -path ./.git -prune -o -type f \( -name Dockerfile -o -name 'Dockerfile.*' \) -print | sort)

if ((failed)); then
    exit 1
fi

echo "OK: every Buildx step uses the docker-container driver with ${pins[0]}; no Dockerfile has a # syntax= line"
