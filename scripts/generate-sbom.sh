#!/usr/bin/env bash
# Generate per-artifact SPDX 2.3 JSON from versions.mk pins.
#
# Usage:
#   ./scripts/generate-sbom.sh --out-dir DIR ARTIFACT [ARTIFACT...]
#
# ARTIFACT is a release name such as curl-amd64, magic.mgc-arm64, or
# mtr-packet-amd64. Linked prefix libraries come from SBOM_LIBS in the
# tool's versions.mk (or SBOM_LIBS_<name> for extra artifacts).
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
export GENERATE_SBOM_ROOT="${ROOT}"

if [[ $# -lt 3 || "$1" != "--out-dir" ]]; then
    echo "Usage: $0 --out-dir DIR ARTIFACT [ARTIFACT...]" >&2
    exit 2
fi

exec python3 - "$@" <<'PY'
"""Emit deterministic SPDX 2.3 JSON from versions.mk pins."""
from __future__ import annotations

import json
import os
import re
import sys
from pathlib import Path

ASSIGN = re.compile(r"^([A-Za-z0-9_.-]+)[ \t]*:=[ \t]*(.*)$")
EXPAND = re.compile(r"\$\(([^)]+)\)")
ARTIFACT_RE = re.compile(r"^(.+)-(amd64|arm64)$")

# Extra release artifacts that do not share a tools/<name>/ directory.
ARTIFACT_TOOL = {
    "mtr-packet": "mtr",
    "magic.mgc": "file",
}

# SBOM_LIBS keys -> variable prefix in deps/versions.mk
LIB_PREFIX = {
    "openssl": "OPENSSL",
    "zlib": "ZLIB",
    "nghttp2": "NGHTTP2",
    "ncurses": "NCURSES",
    "libcap": "LIBCAP",
    "libuv": "LIBUV",
    "libpcap": "LIBPCAP",
    "xxhash": "XXHASH",
    "zstd": "ZSTD",
    "lz4": "LZ4",
}

CREATED = "1970-01-01T00:00:00Z"
NAMESPACE_BASE = "https://github.com/colinmcintosh/static-tools/sbom"


def die(msg: str) -> None:
    print(f"ERROR: {msg}", file=sys.stderr)
    raise SystemExit(1)


def parse_mk(path: Path) -> dict[str, str]:
    assignments: dict[str, str] = {}
    for raw in path.read_text().splitlines():
        line = raw.split("#", 1)[0].rstrip()
        if not line or line.startswith("include "):
            continue
        match = ASSIGN.match(line)
        if not match:
            continue
        assignments[match.group(1)] = match.group(2)
    return assignments


def expand_value(value: str, env: dict[str, str]) -> str:
    previous = None
    while previous != value:
        previous = value
        value = EXPAND.sub(lambda m: env.get(m.group(1), m.group(0)), value)
    return value


def expand_all(assignments: dict[str, str], base: dict[str, str] | None = None) -> dict[str, str]:
    env = dict(base or {})
    env.update(assignments)
    # Multi-pass so later keys can reference earlier ones and vice versa.
    for _ in range(len(env) + 1):
        changed = False
        for key, val in list(env.items()):
            expanded = expand_value(val, env)
            if expanded != val:
                env[key] = expanded
                changed = True
        if not changed:
            break
    return env


def load_deps(root: Path) -> dict[str, str]:
    return expand_all(parse_mk(root / "deps" / "versions.mk"))


def tool_dir_for(name: str, root: Path) -> Path:
    tool = ARTIFACT_TOOL.get(name, name)
    path = root / "tools" / tool
    if not path.is_dir():
        die(f"unknown artifact '{name}': no tools/{tool}/")
    return path


def tool_source(tool_raw: dict[str, str], deps: dict[str, str]) -> tuple[str, str, str]:
    versions = [k for k in tool_raw if k.endswith("_VERSION") and not k.startswith("SBOM_")]
    if len(versions) == 1:
        prefix = versions[0][: -len("_VERSION")]
        env = expand_all(tool_raw, deps)
        version = env.get(f"{prefix}_VERSION", "")
        url = env.get(f"{prefix}_SOURCE_URL") or env.get(f"{prefix}_URL") or ""
        sha = env.get(f"{prefix}_SOURCE_SHA256") or env.get(f"{prefix}_SHA256") or ""
        if not version or not url or not sha:
            die(f"incomplete source pin for {prefix}")
        return version, url, sha
    if not versions:
        # openssl CLI is the prefix OpenSSL tarball.
        version = deps.get("OPENSSL_VERSION", "")
        url = deps.get("OPENSSL_URL", "")
        sha = deps.get("OPENSSL_SHA256", "")
        if not version or not url or not sha:
            die("openssl artifact is missing OPENSSL_* pins in deps/versions.mk")
        return version, url, sha
    die(f"expected one *_VERSION in tool versions.mk, found {versions}")


def sbom_libs(name: str, tool_raw: dict[str, str]) -> list[str]:
    if "SBOM_LIBS" not in tool_raw:
        die(f"SBOM_LIBS is missing in versions.mk for {name}")
    override = f"SBOM_LIBS_{name}"
    if override in tool_raw:
        raw = tool_raw[override]
    else:
        raw = tool_raw["SBOM_LIBS"]
    return [part for part in raw.split() if part]


def lib_source(lib: str, deps: dict[str, str]) -> tuple[str, str, str]:
    if lib not in LIB_PREFIX:
        die(f"unknown SBOM_LIBS key '{lib}'")
    prefix = LIB_PREFIX[lib]
    version = deps.get(f"{prefix}_VERSION", "")
    url = deps.get(f"{prefix}_URL", "")
    sha = deps.get(f"{prefix}_SHA256", "")
    if not version or not url or not sha:
        die(f"incomplete pin for library '{lib}' ({prefix}_*)")
    return version, url, sha


def spdx_id(name: str) -> str:
    return "SPDXRef-Package-" + name


def package(
    name: str,
    version: str,
    url: str,
    sha256: str,
) -> dict:
    return {
        "SPDXID": spdx_id(name),
        "name": name,
        "versionInfo": version,
        "downloadLocation": url,
        "filesAnalyzed": False,
        "licenseConcluded": "NOASSERTION",
        "licenseDeclared": "NOASSERTION",
        "copyrightText": "NOASSERTION",
        "checksums": [
            {
                "algorithm": "SHA256",
                "checksumValue": sha256,
            }
        ],
    }


def generate_one(artifact: str, root: Path) -> dict:
    match = ARTIFACT_RE.match(artifact)
    if not match:
        die(f"artifact '{artifact}' must look like name-amd64 or name-arm64")
    name = match.group(1)
    tool_path = tool_dir_for(name, root)
    tool_raw = parse_mk(tool_path / "versions.mk")
    deps = load_deps(root)
    version, url, sha = tool_source(tool_raw, deps)
    libs = sbom_libs(name, tool_raw)

    packages = [package(artifact, version, url, sha)]
    relationships = [
        {
            "spdxElementId": "SPDXRef-DOCUMENT",
            "relationshipType": "DESCRIBES",
            "relatedSpdxElement": spdx_id(artifact),
        }
    ]
    for lib in libs:
        lib_version, lib_url, lib_sha = lib_source(lib, deps)
        packages.append(package(lib, lib_version, lib_url, lib_sha))
        relationships.append(
            {
                "spdxElementId": spdx_id(artifact),
                "relationshipType": "DEPENDS_ON",
                "relatedSpdxElement": spdx_id(lib),
            }
        )

    return {
        "spdxVersion": "SPDX-2.3",
        "dataLicense": "CC0-1.0",
        "SPDXID": "SPDXRef-DOCUMENT",
        "name": artifact,
        "documentNamespace": f"{NAMESPACE_BASE}/{artifact}/{version}",
        "creationInfo": {
            "created": CREATED,
            "creators": [
                "Tool: static-tools-generate-sbom",
                "Organization: colinmcintosh/static-tools",
            ],
        },
        "documentDescribes": [spdx_id(artifact)],
        "packages": packages,
        "relationships": relationships,
    }


def main(argv: list[str]) -> None:
    if len(argv) < 3 or argv[0] != "--out-dir":
        die("Usage: generate-sbom.sh --out-dir DIR ARTIFACT [ARTIFACT...]")
    out_dir = Path(argv[1])
    artifacts = argv[2:]
    root = Path(os.environ["GENERATE_SBOM_ROOT"])
    out_dir.mkdir(parents=True, exist_ok=True)
    for artifact in artifacts:
        doc = generate_one(artifact, root)
        dest = out_dir / f"{artifact}.spdx.json"
        dest.write_text(json.dumps(doc, indent=2, sort_keys=False) + "\n")
        print(dest)


if __name__ == "__main__":
    main(sys.argv[1:])
PY
