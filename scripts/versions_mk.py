"""Read `NAME := value` pins from versions.mk files.

Shared by generate-sbom.sh and verify-upstream-signatures.sh. This handles
the subset versions.mk files use, not Makefile syntax in general: `:=`
assignments, `#` comments, `$(NAME)` references, and `include` lines, which
are skipped (pass the included file's variables as `base`).
"""
from __future__ import annotations

import re
from pathlib import Path

ASSIGN = re.compile(r"^([A-Za-z0-9_.-]+)[ \t]*:=[ \t]*(.*)$")
EXPAND = re.compile(r"\$\(([^)]+)\)")


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
