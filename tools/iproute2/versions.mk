# iproute2 version and checksums
# All versions and checksums should be pinned for reproducibility

include ../../deps/versions.mk

# iproute2 source (tar.gz so the tool build does not need xz; upstream also
# publishes a .tar.xz of the same release).
IPROUTE2_VERSION := 7.2.0
IPROUTE2_SOURCE_URL := https://www.kernel.org/pub/linux/utils/net/iproute2/iproute2-$(IPROUTE2_VERSION).tar.gz
IPROUTE2_SOURCE_SHA256 := fad570d3b044715955f816422264897bdb1b315d2b41e42ffbbf0989c9b3f7cd

# Prefix libraries statically linked into this artifact (SBOM). iproute2's
# configure writes -lcap onto the global LDLIBS once libcap.pc is found, so
# both link lines mention it. Only `ip` actually calls drop_cap()/cap_*
# (lib/utils.c, used for `ip netns`); `ss` does not, and Alpine's
# --as-needed drops the unused archive from the ss binary.
SBOM_LIBS := libcap
SBOM_LIBS_ss :=
