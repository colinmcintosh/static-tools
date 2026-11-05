# ipmitool version and checksums
# All versions and checksums should be pinned for reproducibility

include ../../deps/versions.mk

# GitHub tag archive. The tag is IPMITOOL_1_8_19; there is no stored
# release tarball asset besides that archive.
IPMITOOL_VERSION := 1.8.19
IPMITOOL_SOURCE_URL := https://github.com/ipmitool/ipmitool/archive/refs/tags/IPMITOOL_1_8_19.tar.gz
IPMITOOL_SOURCE_SHA256 := 48b010e7bcdf93e4e4b6e43c53c7f60aa6873d574cbd45a8d86fa7aaeebaff9c

# Prefix libraries statically linked into this artifact (SBOM).
SBOM_LIBS := openssl
