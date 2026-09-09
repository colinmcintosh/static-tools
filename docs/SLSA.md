# SLSA Build L3

This repository claims [SLSA](https://slsa.dev/) v1.2 **Build L3** for release
binaries published from GitHub Actions.

It does **not** claim Source L3 (there is no gittuf). It is not hermetic or
bit-for-bit reproducible (Build L4-class).

## How

- Builds run on GitHub-hosted ephemeral runners (`ubuntu-24.04` and
  `ubuntu-24.04-arm`), inside digest-pinned Alpine containers.
- Upstream tarballs are fetched over HTTPS and verified with SHA256 pins in
  each tool's `versions.mk` (shared libraries live in `deps/versions.mk`).
- The shared static prefix is built once per architecture in the same release
  run (no cross-run cache). `deps` and `build` have `contents: read` only.
- The `build` job in [`.github/workflows/release.yml`](../.github/workflows/release.yml)
  cannot mint OIDC tokens or write attestations.
- Provenance is signed in the reusable workflow
  [`.github/workflows/attest.yml`](../.github/workflows/attest.yml) using
  SHA-pinned `actions/attest` (Sigstore keyless signing). Isolation of signing
  from the build job is what satisfies Build L3.
- Releases are published as GitHub Releases. Treat released assets as
  immutable: verify them, do not re-tag or overwrite.

## Verify

1. Attestation (pin the signer workflow):

   ```bash
   gh attestation verify curl-amd64 \
     --repo colinmcintosh/static-tools \
     --signer-workflow colinmcintosh/static-tools/.github/workflows/attest.yml
   ```

   Or: `./scripts/verify.sh curl-amd64` (requires the GitHub CLI).

2. Checksums:

   ```bash
   sha256sum -c SHA256SUMS.txt
   ```

## Source

Source integrity on `main` is enforced with a GitHub branch ruleset: required
commit signatures, no force-push, no branch deletion. That is not Source L3
and is not gittuf.

## Exceptions

- **`dig`**: BIND **9.16.50** is the last autoconf line that still links
  statically. Newer BIND uses Meson and is not built here. 9.16 is
  upstream-EOL; this is an explicit exception, not a Meson rewrite.
- **`file`**: libmagic does not search next to the binary. Use
  `file -m magic.mgc-<arch>` or set `MAGIC=` to the shipped magic file.
