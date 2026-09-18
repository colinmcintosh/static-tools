#!/usr/bin/env bash
#
# Verify that each versions.mk pin with a detached signature matches a
# tarball signed by a committed upstream key. SHA256 in the Docker build
# is the bit-identity check; this proves the recorded hash is the hash of
# an upstream-signed artifact.
#
# Usage:
#   scripts/verify-upstream-signatures.sh
#
# Environment:
#   ROOT            Repository root (default: parent of this script)
#   KEYS_DIR        Directory of committed .asc key files
#   CACHE_DIR       Where tarballs and signatures are downloaded
#
# Never fetches keys from a keyserver.
#
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT="${ROOT:-$(cd "${SCRIPT_DIR}/.." && pwd)}"
KEYS_DIR="${KEYS_DIR:-${SCRIPT_DIR}/upstream-keys}"
if [[ -z "${CACHE_DIR:-}" ]]; then
    CACHE_DIR=$(mktemp -d)
    trap 'rm -rf "${CACHE_DIR}"' EXIT
fi
mkdir -p "${CACHE_DIR}"
export PYTHONUNBUFFERED=1

exec python3 - "${ROOT}" "${KEYS_DIR}" "${CACHE_DIR}" <<'PY'
"""Download pinned tarballs, gpg --verify with committed keys, check SHA256."""
from __future__ import annotations

import hashlib
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

ASSIGN = re.compile(r"^([A-Za-z0-9_.-]+)[ \t]*:=[ \t]*(.*)$")
EXPAND = re.compile(r"\$\(([^)]+)\)")

root = Path(sys.argv[1])
keys_dir = Path(sys.argv[2])
cache_dir = Path(sys.argv[3])


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


def fetch(url: str, dest: Path) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    if dest.is_file() and dest.stat().st_size > 0:
        return
    tmp = dest.with_suffix(dest.suffix + ".part")
    request = Request(
        url,
        headers={
            "User-Agent": (
                "static-tools-signature-audit/1.0 "
                "(+https://github.com/colinmcintosh/static-tools)"
            )
        },
    )
    last_error: Exception | None = None
    for attempt in range(3):
        try:
            with urlopen(request, timeout=60) as resp, tmp.open("wb") as out:
                while True:
                    chunk = resp.read(1024 * 256)
                    if not chunk:
                        break
                    out.write(chunk)
            tmp.replace(dest)
            return
        except (HTTPError, URLError, TimeoutError, OSError) as exc:
            last_error = exc
            if tmp.exists():
                tmp.unlink()
            if attempt < 2:
                continue
    die(f"download failed: {url}: {last_error}")


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(1024 * 256), b""):
            h.update(chunk)
    return h.hexdigest()


def gpg_verify(key_file: Path, sig: Path, tarball: Path) -> None:
    with tempfile.TemporaryDirectory(prefix="st-gpg-") as homedir:
        env = os.environ.copy()
        env["GNUPGHOME"] = homedir
        keyring = str(Path(homedir) / "trusted.kbx")
        common = [
            "gpg",
            "--batch",
            "--no-tty",
            "--homedir",
            homedir,
            "--no-default-keyring",
            "--keyring",
            keyring,
        ]
        imported = subprocess.run(
            [*common, "--import", str(key_file)],
            env=env,
            capture_output=True,
            text=True,
        )
        if imported.returncode != 0:
            die(f"gpg --import {key_file} failed:\n{imported.stderr}")
        verify = subprocess.run(
            [
                *common,
                "--trust-model",
                "always",
                "--verify",
                str(sig),
                str(tarball),
            ],
            env=env,
            capture_output=True,
            text=True,
        )
        if verify.returncode != 0:
            die(
                f"gpg --verify failed for {tarball.name}:\n"
                f"{verify.stderr or verify.stdout}"
            )


def collect_pins() -> list[tuple[str, dict[str, str]]]:
    deps = expand_all(parse_mk(root / "deps" / "versions.mk"))
    pins: list[tuple[str, dict[str, str]]] = [("deps", deps)]
    for mk in sorted((root / "tools").glob("*/versions.mk")):
        raw = parse_mk(mk)
        pins.append((str(mk.relative_to(root)), expand_all(raw, deps)))
    return pins


def pin_fields(env: dict[str, str], prefix: str) -> dict[str, str] | None:
    sig = env.get(f"{prefix}_SOURCE_SIG_URL") or env.get(f"{prefix}_SIG_URL") or ""
    if not sig:
        return None
    url = env.get(f"{prefix}_SOURCE_URL") or env.get(f"{prefix}_URL") or ""
    sha = env.get(f"{prefix}_SOURCE_SHA256") or env.get(f"{prefix}_SHA256") or ""
    key = env.get(f"{prefix}_SOURCE_KEY") or env.get(f"{prefix}_KEY") or ""
    if not url or not sha or not key:
        die(f"{prefix} has a SIG_URL but is missing URL, SHA256, or KEY")
    return {"url": url, "sig": sig, "sha": sha.lower(), "key": key}


seen: set[tuple[str, str]] = set()
checked = 0
for label, env in collect_pins():
    prefixes = set()
    for key in env:
        if key.endswith("_SOURCE_SIG_URL"):
            prefixes.add(key[: -len("_SOURCE_SIG_URL")])
        elif key.endswith("_SIG_URL"):
            prefixes.add(key[: -len("_SIG_URL")])
    for prefix in sorted(prefixes):
        fields = pin_fields(env, prefix)
        if fields is None:
            continue
        ident = (fields["url"], fields["sig"])
        if ident in seen:
            continue
        seen.add(ident)
        key_file = keys_dir / f"{fields['key']}.asc"
        if not key_file.is_file():
            die(f"{prefix}: committed key not found: {key_file}")
        safe = re.sub(r"[^A-Za-z0-9._-]+", "_", prefix.lower())
        tarball = cache_dir / f"{safe}.tar"
        sigpath = cache_dir / f"{safe}.sig"
        print(f"==> {prefix} ({label})")
        print(f"    {fields['url']}")
        fetch(fields["url"], tarball)
        fetch(fields["sig"], sigpath)
        got = sha256_file(tarball)
        if got != fields["sha"]:
            die(f"{prefix}: SHA256 mismatch\n  pin: {fields['sha']}\n  got: {got}")
        gpg_verify(key_file, sigpath, tarball)
        print(f"    signed + SHA256 {got}")
        checked += 1

if checked == 0:
    die("no *_SIG_URL / *_SOURCE_SIG_URL pins found")
print(f"OK: verified {checked} signed upstream tarball pin(s)")
PY
