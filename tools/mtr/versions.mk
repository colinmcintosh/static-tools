# mtr version and checksums
# All versions and checksums should be pinned for reproducibility

include ../../deps/versions.mk

# mtr source
MTR_VERSION := 0.96
MTR_SOURCE_URL := https://github.com/traviscross/mtr/archive/refs/tags/v$(MTR_VERSION).tar.gz
# The Dockerfile applies asn-clip-len.patch (upstream 48e1794) on top.
MTR_SOURCE_SHA256 := 73e6aef3fb6c8b482acb5b5e2b8fa7794045c4f2420276f035ce76c5beae632d

# Prefix libraries statically linked into this artifact (SBOM).
SBOM_LIBS := ncurses
# mtr-packet is the unprivileged helper; it does not link ncurses.
SBOM_LIBS_mtr-packet :=
