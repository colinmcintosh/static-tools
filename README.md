# static-tools

Statically compiled binaries for common Linux tools with verified SLSA Level 3 supply chain provenance.

## Overview

This repository provides statically linked binaries that can run on any Linux system without dependencies. All builds are performed in containers with cryptographically signed provenance attestations, enabling verification of the complete build chain.

The provenance provided by this repository is intended to prove the supply chain between upstream
source code (i.e. the source for the binary being built) and the binary used by an end user. You
can be assured that the binaries provided by this repo are built in public view using legitimate
and verified source code. This does not prove the supply chain for upstream source code.

In the future this repository may classify binaries generated from source code which itself provides
SLSA 3+ provenance. For now that is left up to the user.

## Available Tools

| Tool | Version | Description |
|------|---------|-------------|
| mtr | 0.95 | Network diagnostic combining ping and traceroute |
| drill | 1.8.4 | DNS lookup utility (ldns) - lightweight dig alternative |
| dig | 9.16.50 | DNS lookup utility from BIND - full-featured DNS diagnostics |
| curl | 8.11.1 | Command line URL transfer tool |
| wget | 1.25.0 | Network file retriever |
| iperf3 | 3.18 | Network bandwidth measurement tool |
| tcpdump | 4.99.6 | Packet analyzer |
| ncat | 7.991 | nmap netcat with SSL |
| openssl | 3.3.7 | Cryptography command-line tool |
| rsync | 3.5.0 | Fast incremental file-copying tool |
| socat | 1.8.1.3 | Multipurpose relay (SOcket CAT) |
| jq | 1.8.2 | Command-line JSON processor |
| fping | 5.4 | Ping multiple hosts in parallel |
| strace | 6.17 | System-call tracer |
| ncdu | 1.22 | NCurses disk-usage analyzer |
| file | 5.46 | File type identification (includes magic.mgc) |
| xxd | 1.3.16 | Hex dump utility (tinyxxd) |
| htop | 3.5.3 | Interactive process viewer |

Each tool lives in `tools/<name>/` with its version pinned in `versions.mk`. Release artifacts are named `<tool>-<arch>` (for example `curl-amd64`).

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

### Verify Provenance (Recommended)

Verify the SLSA provenance before using binaries:

```bash
# Install slsa-verifier
go install github.com/slsa-framework/slsa-verifier/v2/cli/slsa-verifier@latest

# Download provenance
curl -LO https://github.com/colinmcintosh/static-tools/releases/latest/download/multiple.intoto.jsonl

slsa-verifier verify-artifact curl-amd64 \
  --provenance-path multiple.intoto.jsonl \
  --source-uri github.com/colinmcintosh/static-tools
```

Or use the included verification script:

```bash
./scripts/verify.sh curl-amd64 multiple.intoto.jsonl
```

## Building Locally

### Prerequisites

- Docker with BuildKit support
- GNU Make

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
│   └── release.yml
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
   - `COPY --from=deps` the shared static prefix (do not `apk add` C libraries)
   - Verify source tarballs with SHA256
   - Compile with `-static` flags
   - If the tool needs a new library, add it to `deps/` first

4. Create `tools/dig/Makefile` with build targets

5. Add `dig` to the `TOOLS` list in the root `Makefile`

6. Update the CI/release workflows matrix

## Supply Chain Security

### SLSA Level 3 Compliance

This project achieves [SLSA Level 3](https://slsa.dev/spec/v1.0/levels) through:

| Requirement | Implementation |
|-------------|----------------|
| **Provenance generation** | slsa-github-generator |
| **Signed provenance** | Sigstore (keyless signing via Fulcio) |
| **Isolated builds** | GitHub Actions + container builds |
| **Unforgeable provenance** | Reusable workflows with isolated signing |

### Version Pinning

All dependencies are pinned for reproducibility:

- **Base images**: Alpine pinned by SHA256 digest
- **Source code**: Verified with SHA256 checksums
- **GitHub Actions**: Pinned by commit SHA
- **C libraries**: Built from upstream tarballs pinned by URL + SHA256 (`deps/versions.mk`)
- **Compiler**: Alpine `build-base` / `linux-headers` on the digest-pinned base image (official `gcc` images are glibc/Debian-only)

### Verification

Every release includes:

- `SHA256SUMS.txt` - Checksums for all binaries
- `multiple.intoto.jsonl` - SLSA provenance attestation

## License

MIT License - see [LICENSE](LICENSE) for details.

Individual tools retain their upstream licenses. See the corresponding upstream project.
