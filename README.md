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
| file | 5.46 | File type identification (includes `magic.mgc`; save `magic.mgc-<arch>` as `magic.mgc`, then use `file -m magic.mgc` or `MAGIC=`) |
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

`file` does not search for magic next to the binary. libmagic also only loads a
compiled magic file whose name ends in `.mgc`, so save `magic.mgc-<arch>` as
`magic.mgc`:

```bash
curl -LO https://github.com/colinmcintosh/static-tools/releases/latest/download/file-amd64
curl -L -o magic.mgc https://github.com/colinmcintosh/static-tools/releases/latest/download/magic.mgc-amd64
chmod +x file-amd64
./file-amd64 -m magic.mgc /path/to/something
# or: MAGIC="$PWD/magic.mgc" ./file-amd64 /path/to/something
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

The same flags verify `SHA256SUMS.txt`, which is also a provenance subject:

```bash
gh attestation verify SHA256SUMS.txt \
  --repo colinmcintosh/static-tools \
  --cert-identity https://github.com/colinmcintosh/static-tools/.github/workflows/attest.yml@refs/tags/v2026.09.3 \
  --source-ref refs/tags/v2026.09.3 \
  --deny-self-hosted-runners
```

Or use the included wrapper (also requires `gh`; it does not bootstrap a verifier):

```bash
./scripts/verify.sh v2026.09.3 curl-amd64 SHA256SUMS.txt
```

Substitute the tag of the release you downloaded. `SHA256SUMS.txt` and SBOM attestations exist only for releases after
`v2026.09.6`; against older tags the commands that use them fail with "no
attestations found". Use a newer tag for those examples.

Pinning the tag matters:
`--cert-identity` binds both the signing workflow and the ref it ran from,
while `--signer-workflow` matches only the workflow path and would accept an
attestation produced from any branch.

Then check checksums. `SHA256SUMS.txt` lists every artifact for both
architectures, so skip the ones you did not download:

```bash
sha256sum -c --ignore-missing SHA256SUMS.txt
```

Each binary also has a signed SPDX 2.3 SBOM attestation that lists the pinned
tool tarball and the prefix libraries linked into it (OpenSSL, zlib, and so
on). `gh attestation verify` defaults to SLSA provenance; pass
`--predicate-type` to read the SBOM:

```bash
gh attestation verify curl-amd64 \
  --repo colinmcintosh/static-tools \
  --cert-identity https://github.com/colinmcintosh/static-tools/.github/workflows/attest.yml@refs/tags/v2026.09.3 \
  --source-ref refs/tags/v2026.09.3 \
  --deny-self-hosted-runners \
  --predicate-type https://spdx.dev/Document/v2.3 \
  --format json
```

`--format json` prints the verified statement, including the SPDX packages.
To save the signed bundle instead:

```bash
gh attestation download curl-amd64 \
  --repo colinmcintosh/static-tools \
  --predicate-type https://spdx.dev/Document/v2.3
```

### One-liner

**Warning:** These are dangerous. They download, check, and then **rename files into the current directory** (`curl`, `wget`, `openssl`, `file`, `magic.mgc`, and the rest). That can overwrite or alter files already there — including tools on your `PATH` if you run it in a system directory such as `/usr/local/bin`. Use an empty directory you control.

The parentheses `( ... )` start a subshell so `set -eu` cannot leak into your interactive shell. `file` still needs `./file -m magic.mgc`.

#### With GitHub CLI

Requires the [GitHub CLI](https://cli.github.com/). Checks `SHA256SUMS.txt` and verifies SLSA provenance for the binaries and the sums file (signer workflow, release tag, GitHub-hosted runners).

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
  gh attestation verify SHA256SUMS.txt \
    --repo colinmcintosh/static-tools \
    --cert-identity "https://github.com/colinmcintosh/static-tools/.github/workflows/attest.yml@refs/tags/$t" \
    --source-ref "refs/tags/$t" \
    --deny-self-hosted-runners
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

No `gh`. This only downloads the latest release assets for your architecture and checks them against the `SHA256SUMS.txt` published in that same release. It does **not** verify attestations, so it cannot tell you that the binaries were built by `.github/workflows/attest.yml` on the release tag, or that the sums file itself is authentic — even though that file is attested when you use `gh`. Matching checksums only means the bits match whatever GitHub is serving. You are trusting the release assets.

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
make sbom     # Generate SPDX SBOMs from versions.mk pins
make clean    # Remove build artifacts
```

## Project Structure

```
static-tools/
├── Makefile                    # Root build entry point (`TOOLS` list)
├── builder/                    # Digest-pinned builder image (Dockerfile, apk-lock.txt)
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
│   ├── builder.yml           # Publish and attest the builder image
│   ├── ci.yml
│   ├── release.yml
│   └── attest.yml            # Isolated provenance + SBOM signing (workflow_call)
└── scripts/
    ├── collect-release-bins.sh # Collect release binaries; check against make print-artifacts
    ├── generate-sbom.sh      # Pin-file SPDX SBOMs for release artifacts
    └── verify.sh
```

## Adding New Tools

To add a new tool (e.g., `dig`):

1. Create the tool directory structure:
   ```bash
   mkdir -p tools/dig
   ```

2. Create `tools/dig/versions.mk` with pinned versions and `SBOM_LIBS`
   (the prefix libraries this tool actually links; empty is allowed and
   must be written out):
   ```makefile
   DIG_VERSION := 9.18.24
   DIG_SOURCE_SHA256 := <computed-hash>
   SBOM_LIBS := openssl
   ```

3. Create `tools/dig/Dockerfile` following the curl pattern:
   - `FROM` the digest-pinned builder image (do not `apk add`)
   - `COPY --from=deps` the shared static prefix unless the tool does not link the prefix
   - Verify source tarballs with SHA256
   - Compile with `-fPIE` / `-static-pie` so the binary is a static PIE
   - Assert linkage with `readelf` (no `INTERP`, `Type: DYN`), not `file`
   - If the tool needs a new library, add it to `deps/` first

4. Create `tools/dig/Makefile` with build targets

5. Add `dig` to the `TOOLS` list in the root `Makefile`

6. Update the CI/release build matrices. The release checks the built
   binaries against `make print-artifacts` and derives the `attest-sbom`
   matrix from them, so there are no counts to bump. Extra artifacts (like
   `mtr-packet` or `magic.mgc`) must be added to `ARTIFACTS` in the root
   `Makefile`; if they share a tool tarball but not its libraries, they also
   need `SBOM_LIBS_<name> :=` in that tool's `versions.mk`.

## Supply Chain Security

Details are in [docs/SLSA.md](docs/SLSA.md). Summary:

| Requirement | Implementation |
|-------------|----------------|
| **Provenance generation** | GitHub Artifact Attestations (`actions/attest`) |
| **Signed provenance** | Sigstore (keyless signing via Fulcio) |
| **SBOM** | Per-binary SPDX 2.3 attestation from `versions.mk` pins |
| **Isolated builds** | GitHub-hosted runners + container builds |
| **Unforgeable provenance** | Reusable `attest.yml`; build job has no OIDC |

### Version Pinning

What determines the bits in a release binary is pinned:

- **Builder image**: compiler, static libc, autotools, and headers, pinned by the multi-arch index digest (`BUILDER_DIGEST` in `deps/versions.mk`). Published and attested by `.github/workflows/builder.yml`.
- **Source code**: tool tarballs verified with SHA256 checksums
- **C libraries**: built from upstream tarballs pinned by URL + SHA256 (`deps/versions.mk`)
- **GitHub Actions**: pinned by commit SHA
- **Test runtime**: Alpine pinned by the multi-arch index digest (`ALPINE_DIGEST` in `deps/versions.mk`)

### Verification

Every release includes `SHA256SUMS.txt`, which is itself a provenance subject. Provenance and per-binary SPDX SBOMs are stored as GitHub Artifact Attestations (not a `multiple.intoto.jsonl` release asset). Verify provenance with `gh attestation verify` as above; add `--predicate-type https://spdx.dev/Document/v2.3` to read the SBOM.

## Known Issues

### `dig` stays on BIND 9.16.50 (upstream EOL)

BIND **9.16.50** is a permanent pin. There is no plan to upgrade BIND, drop `dig`, or replace it. Later branches do not support a static-pie `dig`. 9.16 is upstream-EOL.

### `file` does not find `magic.mgc` next to the binary

libmagic does not search next to the binary. Pass the shipped magic file with `file -m` or set `MAGIC=`. The file must be named with a `.mgc` suffix: `file -m magic.mgc-<arch>` fails with "could not find any valid magic files!", so save it as `magic.mgc` first.

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

The builder image is still based on Alpine 3.21.7. Rebuild it from 3.24 before EOL; that work is tracked in [#44](https://github.com/colinmcintosh/static-tools/issues/44).

## License

MIT License - see [LICENSE](LICENSE) for details.

Individual tools retain their upstream licenses. See the corresponding upstream project.
