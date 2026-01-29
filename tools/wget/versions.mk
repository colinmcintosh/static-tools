# wget version and checksums
# All versions and checksums should be pinned for reproducibility

# wget source
WGET_VERSION := 1.25.0
WGET_SOURCE_URL := https://ftp.gnu.org/gnu/wget/wget-$(WGET_VERSION).tar.gz
WGET_SOURCE_SHA256 := 766e48423e79359ea31e41db9e5c289675947a7fcf2efdcedb726ac9d0da3784

# Alpine base image (pinned by digest for reproducibility)
ALPINE_VERSION := 3.21
ALPINE_DIGEST_AMD64 := sha256:41c81533144786e0beb2b148667355a6c7659aa99a14ed837ff15a98ca9d71f3
ALPINE_DIGEST_ARM64 := sha256:fac2338de28c1143c0e69b48ba2d9b50481d5f1542b46c4656e5d6912d2d963a

# Image reference helper (use digest for the target architecture)
define alpine_image
alpine:$(ALPINE_VERSION)@$(if $(filter amd64,$(1)),$(ALPINE_DIGEST_AMD64),$(ALPINE_DIGEST_ARM64))
endef
