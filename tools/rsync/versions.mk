# rsync version and checksums
# All versions and checksums should be pinned for reproducibility

include ../../deps/versions.mk

RSYNC_VERSION := 3.5.0
RSYNC_SOURCE_URL := https://github.com/RsyncProject/rsync/releases/download/v$(RSYNC_VERSION)/rsync-$(RSYNC_VERSION).tar.gz
RSYNC_SOURCE_SHA256 := c7ffd1ef653e99540f661e47cb00b7f9cad1ee6b972399b16f93d672656e0d33
