# sysstat version and checksums
# All versions and checksums should be pinned for reproducibility

include ../../deps/versions.mk

# sysstat source. Upstream (https://github.com/sysstat/sysstat) does not
# publish uploaded release tarball assets, only tags, so pin the GitHub
# auto-generated tag archive.
SYSSTAT_VERSION := 12.8.0
SYSSTAT_SOURCE_URL := https://github.com/sysstat/sysstat/archive/refs/tags/v$(SYSSTAT_VERSION).tar.gz
SYSSTAT_SOURCE_SHA256 := 8aa2054c56c941ab30e1b14ad2e0076a7e6d6bf01f50e22d954885b8a7f9a679

# Prefix libraries statically linked into this artifact (SBOM). Applies to
# all five binaries (mpstat, iostat, pidstat, sar, sadc) alike.
SBOM_LIBS :=
