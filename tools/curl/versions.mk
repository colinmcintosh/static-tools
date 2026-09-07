# curl version and checksums
# All versions and checksums should be pinned for reproducibility

# curl source
CURL_VERSION := 8.11.1
CURL_SOURCE_URL := https://curl.se/download/curl-$(CURL_VERSION).tar.xz
CURL_SOURCE_SHA256 := c7ca7db48b0909743eaef34250da02c19bc61d4f1dcedd6603f109409536ab56

# Alpine base image (pinned by digest for reproducibility)
ALPINE_VERSION := 3.21
ALPINE_DIGEST_AMD64 := sha256:41c81533144786e0beb2b148667355a6c7659aa99a14ed837ff15a98ca9d71f3
ALPINE_DIGEST_ARM64 := sha256:fac2338de28c1143c0e69b48ba2d9b50481d5f1542b46c4656e5d6912d2d963a

# Image reference helper (use digest for the target architecture)
define alpine_image
alpine:$(ALPINE_VERSION)@$(if $(filter amd64,$(1)),$(ALPINE_DIGEST_AMD64),$(ALPINE_DIGEST_ARM64))
endef
