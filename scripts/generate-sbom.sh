#!/usr/bin/env bash
# Generate per-artifact SPDX 2.3 JSON from versions.mk pins.
#
# Usage:
#   ./scripts/generate-sbom.sh [--tag TAG] --out-dir DIR ARTIFACT [ARTIFACT...]
#
# TAG goes into each documentNamespace so a dependency-only pin bump yields a
# new namespace. It defaults to `git describe --tags --always --dirty`.
#
# ARTIFACT is a release name such as curl-amd64, magic.mgc-arm64, or
# mtr-packet-amd64. Linked prefix libraries come from SBOM_LIBS in the
# tool's versions.mk (or SBOM_LIBS_<name> for extra artifacts).
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT=$(cd "${SCRIPT_DIR}/.." && pwd)

# versions_mk.py (the shared versions.mk reader) sits next to this script.
export PYTHONPATH="${SCRIPT_DIR}"
exec python3 -B - "${ROOT}" "$@" <<'PY'
"""Emit deterministic SPDX 2.3 JSON from versions.mk pins."""
from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

from versions_mk import expand_all, parse_mk

ARTIFACT_RE = re.compile(r"^(.+)-(amd64|arm64)$")

# Extra release artifacts that do not share a tools/<name>/ directory.
ARTIFACT_TOOL = {
    "mtr-packet": "mtr",
    "magic.mgc": "file",
    "nmap-services": "nmap",
    "ip": "iproute2",
    "ss": "iproute2",
    "getcap": "libcap",
    "setcap": "libcap",
    "mpstat": "sysstat",
    "iostat": "sysstat",
    "pidstat": "sysstat",
    "sar": "sysstat",
    "sadc": "sysstat",
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


def generate_one(artifact: str, root: Path, deps: dict[str, str], tag: str) -> dict:
    match = ARTIFACT_RE.match(artifact)
    if not match:
        die(f"artifact '{artifact}' must look like name-amd64 or name-arm64")
    name = match.group(1)
    tool_path = tool_dir_for(name, root)
    tool_raw = parse_mk(tool_path / "versions.mk")
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
        "documentNamespace": f"{NAMESPACE_BASE}/{tag}/{artifact}",
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


def default_tag(root: Path) -> str:
    try:
        out = subprocess.run(
            ["git", "-C", str(root), "describe", "--tags", "--always", "--dirty"],
            check=True,
            capture_output=True,
            text=True,
        )
    except (OSError, subprocess.CalledProcessError):
        die("could not determine a tag with git describe; pass --tag")
    return out.stdout.strip()


def main(argv: list[str]) -> None:
    root = Path(argv[0])
    parser = argparse.ArgumentParser(prog="generate-sbom.sh")
    parser.add_argument("--tag")
    parser.add_argument("--out-dir", required=True, type=Path)
    parser.add_argument("artifacts", nargs="+", metavar="ARTIFACT")
    args = parser.parse_args(argv[1:])
    tag = args.tag or default_tag(root)
    deps = load_deps(root)
    args.out_dir.mkdir(parents=True, exist_ok=True)
    for artifact in args.artifacts:
        doc = generate_one(artifact, root, deps, tag)
        dest = args.out_dir / f"{artifact}.spdx.json"
        dest.write_text(json.dumps(doc, indent=2, sort_keys=False) + "\n")
        print(dest)


if __name__ == "__main__":
    main(sys.argv[1:])
PY
