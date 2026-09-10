# static-tools

Statically compiled binaries for common Linux tools with SLSA v1.2 Build L3 provenance.

See [docs/SLSA.md](docs/SLSA.md) for the claim, how it is achieved, and how to verify it.

## Overview

This repository provides statically linked PIE binaries that can run on any Linux system without dependencies. They get ASLR (`ET_DYN`, no interpreter). Release builds run in digest-pinned containers. Provenance is signed in an isolated reusable workflow so the build job cannot mint attestations.

The provenance is intended to prove the supply chain between upstream source (the tarball being built) and the binary an end user downloads. It does not prove the supply chain of that upstream source.

## Available Tools

| Tool | Version | Description |
|------|---------|-------------|
| mtr | 0.95 | Network diagnostic combining ping and traceroute (includes `mtr-packet`) |
| drill | 1.9.2 | DNS lookup utility (ldns) - lightweight dig alternative |
| dig | 9.16.50 | DNS lookup utility from BIND - full-featured DNS diagnostics |
| curl | 8.22.0 | Command line URL transfer tool |
| wget | 1.25.0 | Network file retriever |
| iperf3 | 3.21 | Network bandwidth measurement tool |
| tcpdump | 4.99.6 | Packet analyzer |
| ncat | 7.991 | nmap netcat with SSL |
| openssl | 3.5.8 | Cryptography command-line tool |
| rsync | 3.5.0 | Fast incremental file-copying tool |
| socat | 1.8.1.3 | Multipurpose relay (SOcket CAT) |
| jq | 1.8.2 | Command-line JSON processor |
| fping | 5.4 | Ping multiple hosts in parallel |
| strace | 6.17 | System-call tracer |
| ncdu | 1.22 | NCurses disk-usage analyzer |
| file | 5.46 | File type identification (includes `magic.mgc`; use `file -m magic.mgc-<arch>` or `MAGIC=`) |
| xxd | 1.3.16 | Hex dump utility (tinyxxd) |
| htop | 3.5.3 | Interactive process viewer |

Each tool lives in `tools/<name>/` with its version pinned in `versions.mk`. Release artifacts are named `<tool>-<arch>` (for example `curl-amd64`). `file` also ships `magic.mgc-<arch>`; `mtr` also ships `mtr-packet-<arch>`.

## Supported Architectures

- `amd64` (x86_64)
- `arm64` (aarch64)

## Usage

### Download from Releases

Download the latest binaries from the [Releases](https://github.com/colinmcintosh/static-tools/releases) page. Artifacts are named `<tool>-<arch>`.

```bash
curl -LO https://github.com/colinmcintosh/static-tools/releases/latest/download/curl-amd64
chmod +x curl-amd64
mv curl-amd64 curl
```

`file` does not search for magic next to the binary:

```bash
curl -LO https://github.com/colinmcintosh/static-tools/releases/latest/download/file-amd64
curl -LO https://github.com/colinmcintosh/static-tools/releases/latest/download/magic.mgc-amd64
chmod +x file-amd64
./file-amd64 -m magic.mgc-amd64 /path/to/something
# or: MAGIC=/path/to/magic.mgc-amd64 ./file-amd64 /path/to/something
```

### Verify Provenance (Recommended)

Verify the SLSA provenance before using binaries. Requires the [GitHub CLI](https://cli.github.com/):

```bash
gh attestation verify curl-amd64 \
  --repo colinmcintosh/static-tools \
  --cert-identity https://github.com/colinmcintosh/static-tools/.github/workflows/attest.yml@refs/tags/v2026.09.3 \
  --source-ref refs/tags/v2026.09.3 \
  --deny-self-hosted-runners
```

Or use the included wrapper (also requires `gh`; it does not bootstrap a verifier):

```bash
./scripts/verify.sh v2026.09.3 curl-amd64
```

Substitute the tag of the release you downloaded. Pinning the tag matters:
`--cert-identity` binds both the signing workflow and the ref it ran from,
while `--signer-workflow` matches only the workflow path and would accept an
attestation produced from any branch.

Then check checksums:

```bash
sha256sum -c SHA256SUMS.txt
```

### One-liner

**Warning:** These are dangerous. They download, check, and then **rename files into the current directory** (`curl`, `wget`, `openssl`, `file`, `magic.mgc`, and the rest). That can overwrite or alter files already there — including tools on your `PATH` if you run it in a system directory such as `/usr/local/bin`. Use an empty directory you control.

The parentheses `( ... )` start a subshell so `set -eu` cannot leak into your interactive shell. `file` still needs `./file -m magic.mgc`.

#### With GitHub CLI

Requires the [GitHub CLI](https://cli.github.com/). Checks `SHA256SUMS.txt` and verifies SLSA provenance (signer workflow, release tag, GitHub-hosted runners).

```bash
(
  set -eu
  a=$(uname -m)
  case $a in
    x86_64) a=amd64 ;;
    aarch64) a=arm64 ;;
    *) echo "unsupported: $a" >&2; exit 1 ;;
  esac
  t=$(gh release view -R colinmcintosh/static-tools --json tagName -q .tagName)
  gh release download -R colinmcintosh/static-tools --clobber -p "*-$a" -p SHA256SUMS.txt
  sha256sum -c --ignore-missing SHA256SUMS.txt
  printf '%s\0' *-"$a" | xargs -0 -P"$(nproc)" -I{} bash -c '
    f=$1 t=$2
    if gh attestation verify "$f" \
         --repo colinmcintosh/static-tools \
         --cert-identity "https://github.com/colinmcintosh/static-tools/.github/workflows/attest.yml@refs/tags/$t" \
         --source-ref "refs/tags/$t" \
         --deny-self-hosted-runners >/dev/null 2>&1; then
      printf "%s: VERIFIED\n" "$f"
    else
      printf "%s: FAILED\n" "$f" >&2
      exit 1
    fi
  ' _ {} "$t"
  for f in *-"$a"; do
    d=${f%-$a}
    mv "$f" "$d"
    [ "$d" = magic.mgc ] || chmod +x "$d"
  done
)
```

#### You-trust-me one-liner

No `gh`. This only downloads the latest release assets for your architecture and checks them against the `SHA256SUMS.txt` published in that same release. It does **not** verify attestations, so it cannot tell you that the binaries were built by `.github/workflows/attest.yml` on the release tag, or that the sums file itself is authentic. Matching checksums only means the bits match whatever GitHub is serving. You are trusting the release assets.

```bash
(
  set -euo pipefail
  a=$(uname -m)
  case $a in
    x86_64) a=amd64 ;;
    aarch64) a=arm64 ;;
    *) echo "unsupported: $a" >&2; exit 1 ;;
  esac
  base=https://github.com/colinmcintosh/static-tools/releases/latest/download
  curl -fsSL -o SHA256SUMS.txt "$base/SHA256SUMS.txt"
  mapfile -t lines < <(grep -- "-$a$" SHA256SUMS.txt)
  ((${#lines[@]})) || { echo "no artifacts for $a" >&2; exit 1; }
  for line in "${lines[@]}"; do
    f=${line##* }
    curl -fsSL -o "$f" "$base/$f"
  done
  printf '%s\n' "${lines[@]}" | sha256sum -c -
  for f in *-"$a"; do
    d=${f%-$a}
    mv "$f" "$d"
    [ "$d" = magic.mgc ] || chmod +x "$d"
  done
)
```

## Building Locally

### Prerequisites

- Docker with BuildKit support
- GNU Make 4.3 or newer (grouped targets for `mtr` and `file`)

### Build for Your Architecture

```bash
# Build the shared static library prefix (openssl, zlib, nghttp2, ...)
make deps

# One tool for the host architecture (replace curl with any name from `make list`)
make build-curl

# All tools
make build
```

### Build for All Architectures

```bash
make build-all-curl   # one tool, amd64 and arm64
make build-all        # all tools, all architectures
```

### Test

```bash
make test-curl   # one tool
make test        # all tools
```

### Other Commands

```bash
make help     # Show all available commands
make list     # List available tools
make clean    # Remove build artifacts
```

## Project Structure

```
static-tools/
├── Makefile                    # Root build entry point (`TOOLS` list)
├── docs/SLSA.md                # Build L3 claim and verification
├── deps/                       # Shared static library prefix
│   ├── Dockerfile
│   ├── Makefile
│   └── versions.mk
├── tools/
│   └── <name>/                 # One directory per tool; `curl/` is the reference
│       ├── Dockerfile
│       ├── Makefile
│       └── versions.mk
├── .github/workflows/
│   ├── ci.yml
│   ├── release.yml
│   └── attest.yml            # Isolated provenance signing (workflow_call)
└── scripts/
    └── verify.sh
```

## Adding New Tools

To add a new tool (e.g., `dig`):

1. Create the tool directory structure:
   ```bash
   mkdir -p tools/dig
   ```

2. Create `tools/dig/versions.mk` with pinned versions:
   ```makefile
   DIG_VERSION := 9.18.24
   DIG_SOURCE_SHA256 := <computed-hash>
   ```

3. Create `tools/dig/Dockerfile` following the curl pattern:
   - Use Alpine with musl for static linking, pinned by digest
   - `COPY --from=deps` the shared static prefix (do not `apk add` C libraries) unless the tool does not link the prefix
   - Verify source tarballs with SHA256
   - Compile with `-fPIE` / `-static-pie` so the binary is a static PIE
   - Assert linkage with `readelf` (no `INTERP`, `Type: DYN`), not `file`
   - If the tool needs a new library, add it to `deps/` first

4. Create `tools/dig/Makefile` with build targets

5. Add `dig` to the `TOOLS` list in the root `Makefile`

6. Update the CI/release workflow matrices, and bump the expected binary count in `release.yml` / `attest.yml` if you add extra artifacts (like `mtr-packet` or `magic.mgc`)

## Supply Chain Security

Details are in [docs/SLSA.md](docs/SLSA.md). Summary:

| Requirement | Implementation |
|-------------|----------------|
| **Provenance generation** | GitHub Artifact Attestations (`actions/attest`) |
| **Signed provenance** | Sigstore (keyless signing via Fulcio) |
| **Isolated builds** | GitHub-hosted runners + container builds |
| **Unforgeable provenance** | Reusable `attest.yml`; build job has no OIDC |

### Version Pinning

All dependencies are pinned for reproducibility:

- **Base images**: Alpine pinned by the multi-arch index digest (`deps/versions.mk`)
- **Source code**: Verified with SHA256 checksums
- **GitHub Actions**: Pinned by commit SHA
- **C libraries**: Built from upstream tarballs pinned by URL + SHA256 (`deps/versions.mk`)
- **Compiler**: Alpine `build-base` / `linux-headers` on the digest-pinned base image (official `gcc` images are glibc/Debian-only)

### Verification

Every release includes `SHA256SUMS.txt`. Provenance is stored as GitHub Artifact Attestations (not a `multiple.intoto.jsonl` release asset). Verify with `gh attestation verify` and `--signer-workflow` as above.

## Known Issues

### `dig` is BIND 9.16.50 (upstream EOL)

BIND **9.16.50** is the last autoconf line that still links statically. Newer BIND uses Meson and is not built here. 9.16 is upstream-EOL.

### `file` does not find `magic.mgc` next to the binary

libmagic does not search next to the binary. Use `file -m magic.mgc-<arch>` or set `MAGIC=` to the shipped magic file.

### `wget` 1.25.0 is the newest release and still has unfixed CVEs

1.25.0 is the latest tarball on ftp.gnu.org. Applicable issues have fixes only as upstream git commits:

- CVE-2026-58470 (5.3) — integer overflow in `parse_content_range()`
- CVE-2026-58471 (5.9) — heap buffer overflow in `convert_fname()`
- CVE-2026-58472 (5.9) — heap buffer overflow in `html_quote_string()`
- CVE-2026-16599 — FTP OPIE/S-KEY unbounded MD5 iteration count (`+opie`)

CVE-2026-58469 (7.5, metalink) does **not** apply: this build is `-metalink`.

### `iperf3` 3.21 server mode is still vulnerable to two DoS CVEs

3.21 is the latest release (2026-04-09). Two server-mode issues have fix commits that postdate 3.21:

- CVE-2026-71217 (7.5) — crafted control-channel JSON causes unbounded stream/thread creation
- CVE-2026-71218 (5.3) — `JSON_read()` allocates on a peer-controlled length with no upper bound

Both require running as a server (`iperf3 -s`). Client-only use is not exposed.

### Alpine 3.21 reaches EOL on 2026-11-01

The builder is pinned to the 3.21.7 index digest. Move to Alpine 3.24 before EOL; that work is tracked in [#44](https://github.com/colinmcintosh/static-tools/issues/44).

## License

MIT License - see [LICENSE](LICENSE) for details.

Individual tools retain their upstream licenses. See the corresponding upstream project.
