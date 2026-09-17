# lsof version and checksums
# All versions and checksums should be pinned for reproducibility

include ../../deps/versions.mk

# lsof source. Upstream moved from the original Purdue distribution to
# lsof-org/lsof on GitHub, which is the actively maintained continuation
# and now builds with a normal GNU Autotools ./configure && make (the
# historical capital-C ./Configure script is gone as of this release).
LSOF_VERSION := 4.99.7
LSOF_SOURCE_URL := https://github.com/lsof-org/lsof/releases/download/$(LSOF_VERSION)/lsof-$(LSOF_VERSION).tar.gz
LSOF_SOURCE_SHA256 := 4a10391aab0b8ce1f539e82a1966693b2a6cf225972a6504ebb7ec4fa71675de

# Prefix libraries statically linked into this artifact (SBOM).
SBOM_LIBS :=
