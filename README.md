# static-tools

Statically compiled binaries for common Linux tools with SLSA v1.2 Build L3 provenance.

See [docs/SLSA.md](docs/SLSA.md) for the claim, how it is achieved, and how to verify it.

## Overview

This repository provides statically linked PIE binaries that can run on any Linux system without dependencies. They get ASLR (`ET_DYN`, no interpreter). Release builds run in digest-pinned containers inside a reusable workflow, `attest.yml`, which also signs their provenance. Only its signing jobs can mint attestations, and those jobs run no repository code.

The provenance is intended to prove the supply chain between upstream source (the tarball being built) and the binary an end user downloads. It does not prove the supply chain of that upstream source.

## Available Tools

| Tool | Version | Description |
|------|---------|-------------|
| mtr | 0.96 | Network diagnostic combining ping and traceroute (includes `mtr-packet`) |
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
| fping | 5.5 | Ping multiple hosts in parallel |
| strace | 7.2 | System-call tracer |
| ncdu | 1.22 | NCurses disk-usage analyzer |
| file | 5.48 | File type identification (includes `magic.mgc`; save `magic.mgc-<arch>` as `magic.mgc`, then use `file -m magic.mgc` or `MAGIC=`) |
| xxd | 1.3.16 | Hex dump utility (tinyxxd) |
| htop | 3.5.3 | Interactive process viewer |
| iproute2 | 7.2.0 | Modern network configuration and socket inspection (ships `ip` and `ss`; no `iproute2` binary) |
| lsof | 4.99.7 | List open files and network sockets per process |
| nmap | 7.991 | Network discovery and port scanner (ships `nmap-services`; NSE/Lua, Nping, Ndiff, Zenmap, and the `-sV`/`-O` data files are omitted) |
| zstd | 1.5.7 | Fast modern compression tool |
| nethogs | 0.9.0 | Per-process network bandwidth monitor (iftop substitute; see Known Issues) |
| whois | 5.6.6 | WHOIS/RDAP domain and IP registration lookup client (built without IDN support) |
| less | 704 | Terminal pager for viewing text a screen at a time |
| sysstat | 12.8.0 | Live CPU/disk/process statistics (ships `mpstat`, `iostat`, `pidstat`, `sar`, and `sadc`; no `sysstat` binary) |
| tree | 2.3.2 | Recursive directory listing as a tree |
| libcap | 2.78 | Inspect and set Linux file capabilities (ships `getcap` and `setcap`; no `libcap` binary) |

Each tool lives in `tools/<name>/` with its version pinned in `versions.mk`. Release artifacts are named `<tool>-<arch>` (for example `curl-amd64`). Some tool directories ship multiple binaries, none of which need match the directory name: `mtr` also ships `mtr-packet-<arch>`; `file` also ships `magic.mgc-<arch>`; `nmap` also ships `nmap-services-<arch>`; `iproute2` ships `ip-<arch>` and `ss-<arch>`; `libcap` ships `getcap-<arch>` and `setcap-<arch>`; `sysstat` ships `mpstat-<arch>`, `iostat-<arch>`, `pidstat-<arch>`, `sar-<arch>`, and `sadc-<arch>`.

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

### `mtr` and `fping` privileges

`mtr-packet` and `fping` open raw sockets, so they need `CAP_NET_RAW`. Grant
that capability to the file. Do **not** make them setuid root:

```bash
sudo setcap cap_net_raw+ep ./mtr-packet
sudo setcap cap_net_raw+ep ./fping
```

Only `mtr-packet` needs the capability. `mtr` itself (which parses DNS and
ASN replies) should stay unprivileged; it runs `mtr-packet` from `PATH`,
then as `<mtr path>-packet`, then from `./mtr-packet`. Rename the downloaded
`mtr-packet-<arch>` to `mtr-packet` so one of those lookups finds it.

With `chmod u+s`, a memory-safety bug in code that parses network-supplied
data becomes local privilege escalation instead of a crash. File capabilities
limit the process to raw sockets.

### Verify Provenance (Recommended)

Verify the SLSA provenance before using binaries. This needs the
[GitHub CLI](https://cli.github.com/). Set `TAG` to the release you downloaded:

```bash
TAG=v2026.09.8
gh attestation verify curl-amd64 \
  --repo colinmcintosh/static-tools \
  --cert-identity "https://github.com/colinmcintosh/static-tools/.github/workflows/attest.yml@refs/tags/$TAG" \
  --source-ref "refs/tags/$TAG" \
  --deny-self-hosted-runners
```

`--cert-identity` pins both the workflow that built and signed the binary and
the tag it ran from. `--signer-workflow` would match that workflow's path on
any branch. The same command verifies `SHA256SUMS.txt`, which is also a
provenance subject. The included wrapper runs these checks (it also needs `gh`).
It also checks that the commit the attestations name is on `main`. The release
workflow checks that too, but it runs from the tagged commit, so only a
verifier can catch a tag pushed on another branch:

```bash
./scripts/verify.sh "$TAG" curl-amd64 SHA256SUMS.txt
```

Then check checksums. `SHA256SUMS.txt` lists every artifact for both
architectures, so skip the ones you did not download:

```bash
sha256sum -c --ignore-missing SHA256SUMS.txt
```

Each binary also has a signed SPDX 2.3 SBOM attestation that lists the pinned
tool tarball and the prefix libraries linked into it (OpenSSL, zlib, and so
on). Add `--predicate-type https://spdx.dev/Document/v2.3 --format json` to the
`gh attestation verify` command above to verify the SBOM and print it. To save
the signed bundle instead:

```bash
gh attestation download curl-amd64 \
  --repo colinmcintosh/static-tools \
  --predicate-type https://spdx.dev/Document/v2.3
```

`SHA256SUMS.txt` and SBOM attestations start with `v2026.09.7`.

### One-liner

**Warning:** These are dangerous. They download, check, and then **rename files into the current directory** (`curl`, `wget`, `openssl`, `file`, `magic.mgc`, and the rest). That can overwrite or alter files already there — including tools on your `PATH` if you run it in a system directory such as `/usr/local/bin`. Use an empty directory you control.

The parentheses `( ... )` start a subshell so `set -eu` cannot leak into your interactive shell. `file` still needs `./file -m magic.mgc`.

#### With GitHub CLI

Requires the [GitHub CLI](https://cli.github.com/). Checks `SHA256SUMS.txt`, verifies SLSA provenance for the binaries and the sums file (signer workflow, release tag, GitHub-hosted runners), and checks that the release commit is on `main`.

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
  c=$(gh attestation verify SHA256SUMS.txt \
    --repo colinmcintosh/static-tools \
    --cert-identity "https://github.com/colinmcintosh/static-tools/.github/workflows/attest.yml@refs/tags/$t" \
    --source-ref "refs/tags/$t" \
    --deny-self-hosted-runners \
    --format json --jq '.[0].verificationResult.signature.certificate.sourceRepositoryDigest')
  case $(gh api "repos/colinmcintosh/static-tools/compare/$c...main" --jq .status) in
    identical|ahead) ;;
    *) echo "release commit $c is not on main" >&2; exit 1 ;;
  esac
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
    [ "$d" = magic.mgc ] || [ "$d" = nmap-services ] || chmod +x "$d"
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
    [ "$d" = magic.mgc ] || [ "$d" = nmap-services ] || chmod +x "$d"
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
├── Makefile                    # Root build entry point
├── builder/                    # Digest-pinned builder image (Dockerfile, apk-lock.txt)
├── docs/SLSA.md                # Build L3 claim and verification
├── deps/                       # Shared static library prefix
│   ├── Dockerfile
│   ├── Makefile
│   └── versions.mk
├── tools/
│   ├── common.mk               # Build rules shared by every tool Makefile
│   ├── files.mk                # Files each tool ships (the one list)
│   └── <name>/                 # One directory per tool; `curl/` is the reference
│       ├── Dockerfile
│       ├── Makefile
│       └── versions.mk
├── .github/workflows/
│   ├── builder.yml           # Publish and attest the builder image
│   ├── ci.yml
│   ├── release.yml           # Verify the tag, call attest.yml, publish
│   └── attest.yml            # Build and sign release binaries (workflow_call)
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
   must be written out). The download URL lives here, not in the Dockerfile:
   ```makefile
   DIG_VERSION := 9.18.24
   DIG_SOURCE_URL := https://downloads.isc.org/isc/bind9/$(DIG_VERSION)/bind-$(DIG_VERSION).tar.xz
   DIG_SOURCE_SHA256 := <computed-hash>
   SBOM_LIBS := openssl
   ```
   Prefer an uploaded release asset over a forge-generated archive. If
   only a forge archive exists, say so in a comment next to the URL.
   If upstream publishes a detached signature, add `*_SOURCE_SIG_URL`
   and `*_SOURCE_KEY` and commit the ASCII-armored key under
   `scripts/upstream-keys/`. Tools that reuse a prefix tarball (see
   `libcap` / `zstd`) keep `*_URL` and `*_SHA256` in `deps/versions.mk`
   instead of a second `*_SOURCE_URL`.

3. Create `tools/dig/Dockerfile` following the curl pattern:
   - No `# syntax=` line; CI and release builds use the digest-pinned
     BuildKit's built-in frontend (`make lint` enforces this)
   - `FROM` the digest-pinned builder image (do not `apk add`)
   - `COPY --from=deps` the shared static prefix unless the tool does not link the prefix
   - `ARG DIG_SOURCE_URL` and `wget -q "${DIG_SOURCE_URL}"` (never a literal URL)
   - Verify source tarballs with SHA256
   - Compile with `-fPIE` / `-static-pie` so the binary is a static PIE
   - Assert linkage with `readelf` (no `INTERP`, `Type: DYN`), not `file`
   - If the tool needs a new library, add it to `deps/` first

4. Create `tools/dig/Makefile` following `tools/curl/Makefile`. It includes
   `versions.mk` and sets `TOOL := dig` and `BUILD_ARGS`, which passes each
   pin through, for example `--build-arg DIG_SOURCE_URL=$(DIG_SOURCE_URL)`
   alongside VERSION and SHA256. It sets `DEPS_LIBS` (the prefix libraries
   it links) and `INPUTS` (patches or scripts the Dockerfile copies) if it
   has any. It then includes `../common.mk`, which holds the build rules,
   and defines `test`.

5. There is no tool list to update: the root `Makefile`, CI, and the
   release all treat every `tools/<name>/` directory as a tool. A tool that
   ships anything besides one binary named after its directory (like
   `mtr-packet` or `magic.mgc`) lists its files in `FILES_<name>` in
   `tools/files.mk`, and non-executables also go in `DATA_FILES`. If those
   files share a tool tarball but not its libraries, they also need
   `SBOM_LIBS_<name> :=` in that tool's `versions.mk`.

## Supply Chain Security

Details are in [docs/SLSA.md](docs/SLSA.md). Summary:

| Requirement | Implementation |
|-------------|----------------|
| **Provenance generation** | GitHub Artifact Attestations (`actions/attest`) |
| **Signed provenance** | Sigstore (keyless signing via Fulcio) |
| **SBOM** | Per-binary SPDX 2.3 attestation from `versions.mk` pins |
| **Isolated builds** | GitHub-hosted runners + container builds |
| **Unforgeable provenance** | Reusable `attest.yml` builds and signs; build jobs have no OIDC; signing jobs run only `download-artifact` and `actions/attest` |

### Version Pinning

What determines the bits in a release binary is pinned:

- **Builder image**: compiler, static libc, autotools, and headers, pinned by the multi-arch index digest (`BUILDER_DIGEST` in `deps/versions.mk`). Published and attested by `.github/workflows/builder.yml`.
- **BuildKit**: `moby/buildkit` pinned by index digest (`BUILDKIT_IMAGE` in the workflows). It runs every `RUN` step and, since no Dockerfile has a `# syntax=` line, supplies the Dockerfile frontend too.
- **Source code**: tool tarballs verified with SHA256 checksums; signed pins are also audited with committed upstream keys
- **C libraries**: built from upstream tarballs pinned by URL + SHA256 (`deps/versions.mk`)
- **GitHub Actions**: pinned by commit SHA
- **Test runtime**: Alpine pinned by the multi-arch index digest (`ALPINE_DIGEST` in `deps/versions.mk`)

### Verification

Every release includes `SHA256SUMS.txt`, which is itself a provenance subject. Provenance and per-binary SPDX SBOMs are stored as GitHub Artifact Attestations (not a `multiple.intoto.jsonl` release asset). Verify provenance with `gh attestation verify` as above; add `--predicate-type https://spdx.dev/Document/v2.3` to read the SBOM.

## Known Issues

### `dig` stays on BIND 9.16.50 (upstream EOL)

BIND **9.16.50** is a permanent pin. There is no plan to upgrade BIND, drop `dig`, or replace it. Later branches do not support a static-pie `dig`. 9.16 is upstream-EOL.

### `ncdu` stays on 1.22 (final 1.x release)

`ncdu` **1.22** is the last release of the C implementation. Upstream's active
line is the 2.x Zig rewrite, which this builder cannot compile. 1.22 has no
known CVEs; the pin is deliberate and will be revisited if one appears.

### `mtr` 0.96 carries one upstream patch

`mtr` 0.96 is the latest release, but a later upstream commit
([48e1794](https://github.com/traviscross/mtr/commit/48e1794414d338ce47abc0f27c25ade8788af9c3))
fixes a possible buffer overrun in the ASN lookup code. The build applies that
commit on top of 0.96 (`tools/mtr/asn-clip-len.patch`) until a release includes it.

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

### `nethogs` ships instead of `iftop`

iftop has had no tagged release from an actively maintained fork in over a decade: the original ex-parrot.com site is dead, the current maintainer's self-hosted `code.blinkace.com/pdw/iftop` has commits but zero tags, and every GitHub mirror is stale. `nethogs` 0.9.0 is an actively maintained equivalent (per-process rather than per-connection) and ships instead.

### `whois` has no IDN support

Built without libidn2: the builder image has no `pkg-config`, and `whois` does not link the shared deps prefix, so upstream's `pkg-config`-based autodetection silently leaves IDN support off. ASCII domain queries work normally; punycode/non-ASCII domain names are not converted.

### Terminal tools use the system's terminfo database

`htop`, `less`, `mtr`, `ncdu`, and `nethogs` link ncurses statically but do not bundle a terminfo database. They look up `$TERM` in `$TERMINFO`, `~/.terminfo`, `$TERMINFO_DIRS`, then `/etc/terminfo`, `/lib/terminfo`, `/usr/share/terminfo`, and `/usr/lib/terminfo`. Most distributions ship a database in one of those. On a host without one, install it (for example `ncurses-terminfo-base` on Alpine) or point `$TERMINFO` at a copy.

### TLS tools use the system's CA certificates

`curl`, `wget`, `openssl`, and the other OpenSSL-linked tools trust the CA certificates in `/etc/ssl/cert.pem` and `/etc/ssl/certs`, where Alpine, Debian, and Fedora/RHEL-family systems keep them. Set `SSL_CERT_FILE` or `SSL_CERT_DIR` to use a different store.

### `sar` live sampling needs the shipped `sadc` next to it

`sar <interval> <count>` execs a separate `sadc` binary. This build looks for `sadc` next to the `sar` executable (`dirname(/proc/self/exe)/sadc`), then the compile-time `SADC_PATH`, then `PATH`. It uses the `sadc` next to `sar` only if that file is owned by root or by `sar`'s owner, is not world-writable, and is group-writable only when `sar` is writable by the same group, so a `sadc` that someone else dropped into the same directory is not run. The download one-liners rename `sar-<arch>` and `sadc-<arch>` into the same directory, so `./sar 1 5` works. Historical mode (`sar` with no interval, or `sar -f <datafile>`) still needs a data file produced by a long-running collector; this release does not ship cron/systemd collection. `mpstat`, `iostat`, and `pidstat` are unaffected, since they always sample `/proc` directly.

### `nmap` ships without NSE, Nping, Ndiff, or Zenmap

Built with `--without-liblua --without-nping --without-ndiff --without-zenmap --without-ncat` to avoid pulling in new dependencies for this static build (`ncat` is already its own tool in this repo, built from the same nmap source tarball). The scripting engine (`--script`) is unavailable because Lua/NSE is disabled. Version detection (`-sV`) and OS detection (`-O`) do not use Lua; they are unavailable here because this build does not ship `nmap-service-probes` or `nmap-os-db`. Ordinary port scans and service-name lookups via the shipped `nmap-services` are unaffected. One upstream source oversight (a `close_nse()` call in `nmap.cc` missing the `#ifndef NOLUA` guard used at every other NSE call site in the same file) is patched at build time; see the comment in `tools/nmap/Dockerfile`.

## License

MIT License - see [LICENSE](LICENSE) for details.

Individual tools retain their upstream licenses. See the corresponding upstream project.
