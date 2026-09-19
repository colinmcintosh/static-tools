# SLSA Build L3

This repository claims [SLSA](https://slsa.dev/) v1.2 **Build L3** for release
binaries published from GitHub Actions.

It does **not** claim Source L3 (there is no gittuf). It is not hermetic or
bit-for-bit reproducible (Build L4-class).

## How

- Builds run on GitHub-hosted ephemeral runners (`ubuntu-24.04` and
  `ubuntu-24.04-arm`), inside a digest-pinned builder image
  (`ghcr.io/colinmcintosh/static-tools/builder`). That image is Alpine
  plus the compiler toolchain; it is published and attested by
  [`.github/workflows/builder.yml`](../.github/workflows/builder.yml),
  which publishes only from `main`. Rebuild it from that workflow, then
  copy the new index digest into [`deps/versions.mk`](../deps/versions.mk)
  and refresh [`builder/apk-lock.txt`](../builder/apk-lock.txt). CI and
  `release.yml` run
  [`scripts/verify-builder-image.sh`](../scripts/verify-builder-image.sh)
  before any build: the pinned digest must carry an attestation from
  `builder.yml` on `main`, and CI also checks the lock against the image.
  Tool and deps Dockerfiles must not `apk add`.
- Upstream tarballs are fetched over HTTPS and verified with SHA256 pins in
  each tool's `versions.mk` (shared libraries live in `deps/versions.mk`).
  Pins that publish a detached signature are also audited on every CI run
  and before a release deps build by
  [`scripts/verify-upstream-signatures.sh`](../scripts/verify-upstream-signatures.sh):
  the recorded SHA256 must be the hash of a tarball that verifies with a
  committed key under
  [`scripts/upstream-keys/`](../scripts/upstream-keys/). In-build SHA256
  remains the bit-identity check extracted by Docker.
- Release binaries are built and signed in the reusable workflow
  [`.github/workflows/attest.yml`](../.github/workflows/attest.yml).
  [`.github/workflows/release.yml`](../.github/workflows/release.yml) calls it
  after verifying the tag, then publishes. The certificate identity you
  verify, `attest.yml@refs/tags/<tag>`, therefore names the workflow that
  built the binaries, which is GitHub's reusable-workflow pattern for
  Build L3.
- The shared static prefix is built once per architecture in the same release
  run (no cross-run cache). The `deps`, `build`, and `manifests` jobs have
  `contents: read` only, so they cannot mint OIDC tokens or write
  attestations.
- Only the `attest` and `attest-sbom` jobs can mint OIDC tokens. They check
  out nothing and run no repository scripts. Their only input is the
  `release-manifests` artifact from the `manifests` job. It holds the
  digests to sign (`SHA256SUMS.txt`, `provenance-subjects.txt`) and the SPDX
  SBOM JSON, not the binaries. Each job calls SHA-pinned `actions/attest`
  (Sigstore keyless signing) with `subject-checksums`, or with
  `subject-name` + `subject-digest` and the SBOM file, and `actions/attest`
  parses those files while it holds the token. Build L3 allows build steps
  to supply output digests. Provenance covers every binary plus
  `SHA256SUMS.txt`. Each binary also gets a per-binary SPDX 2.3 SBOM
  attestation (`sbom-path`); that is a second predicate, not a substitute
  for provenance.
- Release runs take no inputs. A release starts from a tag push, or from
  `workflow_dispatch` run from the tag
  (`gh workflow run release.yml --ref <tag>`). Its only external parameter
  is the tag ref, and the provenance records it
  (`externalParameters.workflow.ref`). Every job checks out `github.sha`,
  the commit the provenance names.
- Each build job stages only the files its tool ships, by name, and
  [`scripts/collect-release-bins.sh`](../scripts/collect-release-bins.sh)
  fails when a file name appears in more than one artifact. One tool's
  build therefore cannot replace another tool's binary.
- BuildKit is pinned by index digest (`BUILDKIT_IMAGE` in the workflows). It
  runs every `RUN` step, and because no Dockerfile has a `# syntax=` line,
  it also supplies the Dockerfile frontend.
  [`scripts/assert-buildkit-pinned.sh`](../scripts/assert-buildkit-pinned.sh)
  enforces both in `make lint`.
- GitHub Actions must be pinned to a full commit SHA
  (`sha_pinning_required`). Dependabot watches the `github-actions`
  ecosystem weekly
  ([`.github/dependabot.yml`](../.github/dependabot.yml)). Tarball pins in
  `versions.mk` are outside Dependabot; watching those is
  [#46](https://github.com/colinmcintosh/static-tools/issues/46).
- Releases are published as GitHub Releases with immutable releases enabled:
  once a release is published, GitHub rejects changes to its assets and
  tag, and a deleted release's tag name cannot be reused. So `release.yml`
  checks everything before publishing: it runs `scripts/verify.sh` on every
  asset, uploads them to a draft with the GitHub CLI, checks that the
  draft's asset digests match the verified files, and publishes last.

## Verify

The [README](../README.md#verify-provenance-recommended) has the commands.
What each flag pins:

- `--cert-identity …/.github/workflows/attest.yml@refs/tags/<tag>` pins the
  workflow that built and signed the binaries *and* the tag it ran from.
  `--signer-workflow` is not enough on its own. It matches only
  `<owner>/<repo>/<path>` and ignores the `@<ref>` part of the certificate
  identity, so it accepts an attestation minted by `attest.yml` from any
  ref, and any workflow in the repository can call `attest.yml`.
- `--source-ref refs/tags/<tag>` additionally pins the ref the source was
  built from.
- `--deny-self-hosted-runners` requires a GitHub-hosted runner.
- `scripts/verify.sh` also reads the source commit from the verified
  certificate and requires it to be on `main` (see [Source](#source)).

`SHA256SUMS.txt` is also a provenance subject. Each binary also has an SPDX
2.3 SBOM attestation (`--predicate-type https://spdx.dev/Document/v2.3`).
Both start with `v2026.09.7`.

## Source

Source integrity on `main` is enforced with a GitHub branch ruleset: required
commit signatures, no force-push, no branch deletion. That is not Source L3
and is not gittuf.

Tags matching `v*` cannot be moved or deleted once created, but tag
*creation* is not restricted. `release.yml` refuses to build a tag whose
commit is not reachable from `origin/main` or is not signed by an allowed
key. CI and the release share one implementation in
[`scripts/verify-commit-signatures.sh`](../scripts/verify-commit-signatures.sh).
Allowed fingerprints are listed in
[`scripts/allowed-signing-keys.txt`](../scripts/allowed-signing-keys.txt).

Those release checks run from the tagged commit's own `release.yml`, so they
catch mistakes but cannot stop someone who can push a branch and a tag. The
check that holds is on the verifier's side: `scripts/verify.sh` requires the
commit the attestations name to be on `main`, so a release built from any
other branch fails verification.

Known limitations of individual tools are listed in the
[README Known Issues](../README.md#known-issues) section.
