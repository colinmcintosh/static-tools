# zstd version and checksums
#
# Reuses the pin from deps/versions.mk (ZSTD_VERSION / ZSTD_URL /
# ZSTD_SHA256) instead of defining a new one. That tarball is already
# fetched and SHA256-verified to build the shared static libzstd.a, so
# reusing it here keeps a single source of truth for the zstd version
# across the shared library and this CLI tool.

include ../../deps/versions.mk

# scripts/generate-sbom.sh parses this file's own lines and does not follow
# `include`, so it needs a literal version assignment here too. Keep this in
# sync with ZSTD_VERSION in deps/versions.mk (the URL/SHA256 above are looked
# up there automatically once this points it at the right prefix).
ZSTD_VERSION := 1.5.7

# Prefix libraries statically linked into this artifact (SBOM). This binary
# is compiled directly from the pinned zstd tarball's own lib/ sources, not
# linked against a separate library, so nothing else to list here.
SBOM_LIBS :=
