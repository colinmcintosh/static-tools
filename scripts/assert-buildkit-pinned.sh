#!/usr/bin/env bash
#
# Fail unless BuildKit is pinned by digest in every workflow that sets up
# Buildx, and no Dockerfile picks its own frontend.
#
# BuildKit runs every RUN step. Without a `# syntax=` line it also supplies
# the Dockerfile frontend, so one digest pins both. Each workflow declares
# BUILDKIT_IMAGE (moby/buildkit:<version>@sha256:<digest>), passes it to
# every docker/setup-buildx-action step, and all workflows use the same pin.
#
# Usage:
#   scripts/assert-buildkit-pinned.sh [repo-root]
#

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT=${1:-"$(cd "${SCRIPT_DIR}/.." && pwd)"}
cd "${ROOT}"

failed=0
pins=()
for wf in .github/workflows/*.yml; do
    steps=$(grep -c 'uses: docker/setup-buildx-action@' "${wf}" || true)
    ((steps > 0)) || continue
    # shellcheck disable=SC2016 # a literal ${{ }} expression, not a shell expansion
    pinned=$(grep -cF 'driver-opts: image=${{ env.BUILDKIT_IMAGE }}' "${wf}" || true)
    if ((pinned != steps)); then
        echo "ERROR: ${wf}: ${pinned} of ${steps} setup-buildx-action steps pass driver-opts: image=\${{ env.BUILDKIT_IMAGE }}" >&2
        failed=1
    fi
    pin=$(sed -n 's/^  BUILDKIT_IMAGE: //p' "${wf}")
    if [[ ! "${pin}" =~ ^moby/buildkit:v[0-9][0-9.]*@sha256:[0-9a-f]{64}$ ]]; then
        echo "ERROR: ${wf}: BUILDKIT_IMAGE must be moby/buildkit:<version>@sha256:<digest>, got '${pin}'" >&2
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

echo "OK: every Buildx workflow pins ${pins[0]}; no Dockerfile has a # syntax= line"
