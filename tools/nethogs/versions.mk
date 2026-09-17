# nethogs version and checksums
# All versions and checksums should be pinned for reproducibility

include ../../deps/versions.mk

# nethogs source (GitHub tag tarball; upstream ships no separate release
# tarball, only git tags)
NETHOGS_VERSION := 0.9.0
NETHOGS_SOURCE_URL := https://github.com/raboof/nethogs/archive/refs/tags/v$(NETHOGS_VERSION).tar.gz
NETHOGS_SOURCE_SHA256 := 5961bef2155c05695d2fe7e79aa11194981b5afd1cad9bf1f259c7f30d5487c3

# Prefix libraries statically linked into this artifact (SBOM).
SBOM_LIBS := libpcap ncurses
