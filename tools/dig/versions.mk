# dig (BIND) version and checksums
# All versions and checksums should be pinned for reproducibility
# Note: Using BIND 9.16.x (last autoconf-based version) which allows static compilation

# BIND source (provides dig)
# 9.16.x is the last version using autoconf - newer versions use Meson and don't support static linking
BIND9_VERSION := 9.16.50
BIND9_SOURCE_URL := https://downloads.isc.org/isc/bind9/$(BIND9_VERSION)/bind-$(BIND9_VERSION).tar.xz
BIND9_SOURCE_SHA256 := 816dbaa3c115019f30fcebd9e8ef8f7637f4adde91c79daa099b035255a15795

# Alpine base image (pinned by digest for reproducibility)
ALPINE_VERSION := 3.21
ALPINE_DIGEST_AMD64 := sha256:41c81533144786e0beb2b148667355a6c7659aa99a14ed837ff15a98ca9d71f3
ALPINE_DIGEST_ARM64 := sha256:fac2338de28c1143c0e69b48ba2d9b50481d5f1542b46c4656e5d6912d2d963a

# Image reference helper (use digest for the target architecture)
define alpine_image
alpine:$(ALPINE_VERSION)@$(if $(filter amd64,$(1)),$(ALPINE_DIGEST_AMD64),$(ALPINE_DIGEST_ARM64))
endef
