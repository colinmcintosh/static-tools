# nmap version and checksums
# All versions and checksums should be pinned for reproducibility

include ../../deps/versions.mk

# nmap source. Canonical distribution point is nmap.org/dist (not a GitHub
# mirror/tag); ncat is also built from this same tarball (see tools/ncat).
NMAP_VERSION := 7.991
NMAP_SOURCE_URL := https://nmap.org/dist/nmap-$(NMAP_VERSION).tar.bz2
NMAP_SOURCE_SHA256 := a5d507f29437bef3bedd4771ff9aaa8fc1c2a109ddba1f5b1cf12027456929be

# Prefix libraries statically linked into this artifact (SBOM). liblinear and
# libpcre2 are the bundled in-tree copies, not the shared prefix, so they are
# not listed here.
SBOM_LIBS := openssl zlib libpcap
# nmap-services is a data file from the same tarball; it links nothing.
SBOM_LIBS_nmap-services :=
