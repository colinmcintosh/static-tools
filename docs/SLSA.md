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

1. Attestation (pin the signer workflow *and* the tag it ran from):

   ```bash
   gh attestation verify curl-amd64 \
     --repo colinmcintosh/static-tools \
     --cert-identity https://github.com/colinmcintosh/static-tools/.github/workflows/attest.yml@refs/tags/v2026.09.3 \
     --source-ref refs/tags/v2026.09.3 \
     --deny-self-hosted-runners
   ```

   Or: `./scripts/verify.sh v2026.09.3 curl-amd64` (requires the GitHub CLI).

   `--signer-workflow` is not sufficient on its own. It matches only
   `<owner>/<repo>/<path>` and discards the `@<ref>` portion of the certificate
   identity, so it accepts an attestation minted by `attest.yml` from any ref.
   `attest.yml` is `workflow_call`, so any workflow in the repository can invoke
   it. `--cert-identity` pins the ref; `--source-ref` additionally pins the ref
   the source was built from.

2. Checksums:

   ```bash
   sha256sum -c SHA256SUMS.txt
   ```

## Source

Source integrity on `main` is enforced with a GitHub branch ruleset: required
commit signatures, no force-push, no branch deletion. That is not Source L3
and is not gittuf.

Tags matching `v*` cannot be moved or deleted once created. Because tag
*creation* is not restricted, `release.yml` additionally requires that the
tagged commit is reachable from `origin/main` and carries an acceptable
signature, so a release cannot be cut from an unreviewed branch. Both workflows
share one implementation in
[`scripts/verify-commit-signatures.sh`](../scripts/verify-commit-signatures.sh).
Allowed fingerprints are listed in
[`scripts/allowed-signing-keys.txt`](../scripts/allowed-signing-keys.txt).

Known limitations of individual tools are listed in the
[README Known Issues](../README.md#known-issues) section.
