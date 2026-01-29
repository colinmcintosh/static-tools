# static-tools

Statically compiled binaries for common Linux tools with verified SLSA Level 3 supply chain provenance.

## Overview

This repository provides statically linked binaries that can run on any Linux system without dependencies. All builds are performed in containers with cryptographically signed provenance attestations, enabling verification of the complete build chain.

The provenance provided by this repository is intended to prove the supply chain between upstream
source code (i.e. the source for the binary being built) and the binary used by an end user. You
and be assured that the binaries provided by this repo are built in public view using legitimate
and verified source code. This does not prove the supply chain for upstream source code.

In the future this repository may classify binaries generated from source code which itself provides
SLSA 3+ provenance. For now that is left up to the user.

## Available Tools

| Tool | Version | Description |
|------|---------|-------------|
| mtr | 0.95 | Network diagnostic combining ping and traceroute |
| drill | 1.8.4 | DNS lookup utility (ldns) - lightweight dig alternative |
| dig | 9.16.50 | DNS lookup utility from BIND - full-featured DNS diagnostics |

## Supported Architectures

- `amd64` (x86_64)
- `arm64` (aarch64)

## Usage

### Download from Releases

Download the latest binaries from the [Releases](https://github.com/colinmcintosh/static-tools/releases) page.

For example:

```bash
# Download mtr for your architecture
curl -LO https://github.com/colinmcintosh/static-tools/releases/latest/download/mtr-amd64
chmod +x mtr-amd64
mv mtr-amd64 mtr

# Download dig for DNS lookups
curl -LO https://github.com/colinmcintosh/static-tools/releases/latest/download/dig-amd64
chmod +x dig-amd64
mv dig-amd64 dig

# Or download drill (lightweight alternative)
curl -LO https://github.com/colinmcintosh/static-tools/releases/latest/download/drill-amd64
chmod +x drill-amd64
mv drill-amd64 drill
```

### Verify Provenance (Recommended)

Verify the SLSA provenance before using binaries:

```bash
# Install slsa-verifier
go install github.com/slsa-framework/slsa-verifier/v2/cli/slsa-verifier@latest

# Download provenance
curl -LO https://github.com/colinmcintosh/static-tools/releases/latest/download/multiple.intoto.jsonl

# Verify mtr
slsa-verifier verify-artifact mtr-amd64 \
  --provenance-path multiple.intoto.jsonl \
  --source-uri github.com/colinmcintosh/static-tools

# Verify dig
slsa-verifier verify-artifact dig-amd64 \
  --provenance-path multiple.intoto.jsonl \
  --source-uri github.com/colinmcintosh/static-tools
```

Or use the included verification script:

```bash
./scripts/verify.sh mtr-amd64 multiple.intoto.jsonl
./scripts/verify.sh dig-amd64 multiple.intoto.jsonl
```

## Building Locally

### Prerequisites

- Docker with BuildKit support
- GNU Make

### Build for Your Architecture

```bash
# Build a specific tool for your current architecture
make build-mtr
make build-dig
make build-drill

# Build all tools
make build
```

### Build for All Architectures

```bash
# Build a specific tool for amd64 and arm64
make build-all-mtr
make build-all-dig
make build-all-drill

# Build all tools for all architectures
make build-all
```

### Test

```bash
make test-mtr
make test-dig
make test-drill

# Test all tools
make test
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
├── Makefile                    # Root build entry point
├── tools/
│   ├── mtr/
│   │   ├── Dockerfile          # Static build configuration
│   │   ├── Makefile            # Tool-specific targets
│   │   └── versions.mk         # Pinned versions and checksums
│   ├── drill/
│   │   ├── Dockerfile          # ldns-based DNS lookup tool
│   │   ├── Makefile
│   │   └── versions.mk
│   └── dig/
│       ├── Dockerfile          # BIND-based DNS lookup tool
│       ├── Makefile
│       └── versions.mk
├── .github/
│   ├── workflows/
│   │   ├── ci.yml              # CI validation
│   │   └── release.yml         # Release with SLSA provenance
│   └── configs/
│       ├── mtr-amd64.toml      # SLSA build config (amd64)
│       └── mtr-arm64.toml      # SLSA build config (arm64)
└── scripts/
    └── verify.sh               # Provenance verification helper
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

3. Create `tools/dig/Dockerfile` following the mtr pattern:
   - Use Alpine with musl for static linking
   - Pin base image by digest
   - Verify source with `ADD --checksum`
   - Compile with `-static` flags

4. Create `tools/dig/Makefile` with build targets

5. Add `dig` to the `TOOLS` list in the root `Makefile`

6. Add SLSA configs in `.github/configs/`

7. Update the CI/release workflows matrix

## Supply Chain Security

### SLSA Level 3 Compliance

This project achieves [SLSA Level 3](https://slsa.dev/spec/v1.0/levels) through:

| Requirement | Implementation |
|-------------|----------------|
| **Provenance generation** | slsa-github-generator |
| **Signed provenance** | Sigstore (keyless signing via Fulcio) |
| **Isolated builds** | GitHub Actions + container builds |
| **Unforgeable provenance** | Reusable workflows with isolated signing |

### Source Provenance with gittuf

This project uses [gittuf](https://gittuf.dev/) to provide cryptographic source provenance, proving that source code changes were made by authorized maintainers following defined policies.

#### Setting Up gittuf (Maintainers)

```bash
# Install gittuf
make gittuf-install

# Initialize gittuf (creates keys and policies)
make gittuf-init

# After making commits, record in the Reference State Log
make gittuf-record

# Push gittuf refs to remote
git push origin refs/gittuf/*
```

#### Verifying Source Provenance

```bash
# Verify that the main branch follows gittuf policy
make gittuf-verify

# Or directly with gittuf
gittuf verify-ref main
```

### Version Pinning

All dependencies are pinned for reproducibility:

- **Base images**: Alpine pinned by SHA256 digest
- **Source code**: Verified with SHA256 checksums
- **GitHub Actions**: Pinned by commit SHA
- **Build dependencies**: Pinned to specific Alpine package versions

### Verification

Every release includes:

- `SHA256SUMS.txt` - Checksums for all binaries
- `multiple.intoto.jsonl` - SLSA provenance attestation

## License

MIT License - see [LICENSE](LICENSE) for details.

Individual tools retain their original licenses:
- mtr: GPL-2.0
- drill (ldns): BSD-3-Clause
- dig (BIND): MPL-2.0
