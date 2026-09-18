# mtr version and checksums
# All versions and checksums should be pinned for reproducibility

include ../../deps/versions.mk

# mtr source. Official release tarball from bitwizard.nl; the project
# README warns that GitHub-generated archives are not the preferred
# releases and lack the generated configure script.
# The Dockerfile applies asn-clip-len.patch (upstream 48e1794) on top.
MTR_VERSION := 0.96
MTR_SOURCE_URL := https://www.bitwizard.nl/mtr/files/mtr-$(MTR_VERSION).tar.gz
MTR_SOURCE_SHA256 := ffd19a9f8d5f616c1ea2f0da9fbf9d1239bcecdf5a68912e831966d20929037a

# Prefix libraries statically linked into this artifact (SBOM).
SBOM_LIBS := ncurses
# mtr-packet is the unprivileged helper; it does not link ncurses.
SBOM_LIBS_mtr-packet :=
