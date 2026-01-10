# mtr version and checksums
# All versions and checksums should be pinned for reproducibility

# mtr source
MTR_VERSION := 0.95
MTR_SOURCE_URL := https://github.com/traviscross/mtr/archive/refs/tags/v$(MTR_VERSION).tar.gz
MTR_SOURCE_SHA256 := 12490fb660ba5fb34df8c06a0f62b4f9cbd11a584fc3f6eceda0a99124e8596f

# Alpine base image (pinned by digest for reproducibility)
ALPINE_VERSION := 3.21
ALPINE_DIGEST_AMD64 := sha256:41c81533144786e0beb2b148667355a6c7659aa99a14ed837ff15a98ca9d71f3
ALPINE_DIGEST_ARM64 := sha256:fac2338de28c1143c0e69b48ba2d9b50481d5f1542b46c4656e5d6912d2d963a

# Image reference helper (use digest for the target architecture)
# Usage: $(call alpine_image,amd64) => alpine:3.21@sha256:...
define alpine_image
alpine:$(ALPINE_VERSION)@$(if $(filter amd64,$(1)),$(ALPINE_DIGEST_AMD64),$(ALPINE_DIGEST_ARM64))
endef
