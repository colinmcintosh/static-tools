# tcpdump version and checksums
# All versions and checksums should be pinned for reproducibility

include ../../deps/versions.mk

TCPDUMP_VERSION := 4.99.6
TCPDUMP_SOURCE_URL := https://www.tcpdump.org/release/tcpdump-$(TCPDUMP_VERSION).tar.gz
TCPDUMP_SOURCE_SHA256 := 5839921a0f67d7d8fa3dacd9cd41e44c89ccb867e8a6db216d62628c7fd14b09
TCPDUMP_SOURCE_SIG_URL := https://www.tcpdump.org/release/tcpdump-$(TCPDUMP_VERSION).tar.gz.sig
TCPDUMP_SOURCE_KEY := tcpdump

# Prefix libraries statically linked into this artifact (SBOM).
SBOM_LIBS := openssl libpcap
