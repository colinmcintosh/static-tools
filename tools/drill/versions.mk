# dig (drill) version and checksums
# All versions and checksums should be pinned for reproducibility
# Note: We use ldns/drill instead of BIND dig because BIND cannot be statically compiled

# ldns source (provides drill, a dig-like DNS tool)
LDNS_VERSION := 1.8.4
LDNS_SOURCE_URL := https://nlnetlabs.nl/downloads/ldns/ldns-$(LDNS_VERSION).tar.gz
LDNS_SOURCE_SHA256 := 838b907594baaff1cd767e95466a7745998ae64bc74be038dccc62e2de2e4247

# Alpine base image (pinned by digest for reproducibility)
ALPINE_VERSION := 3.21
ALPINE_DIGEST_AMD64 := sha256:41c81533144786e0beb2b148667355a6c7659aa99a14ed837ff15a98ca9d71f3
ALPINE_DIGEST_ARM64 := sha256:fac2338de28c1143c0e69b48ba2d9b50481d5f1542b46c4656e5d6912d2d963a

# Image reference helper (use digest for the target architecture)
define alpine_image
alpine:$(ALPINE_VERSION)@$(if $(filter amd64,$(1)),$(ALPINE_DIGEST_AMD64),$(ALPINE_DIGEST_ARM64))
endef
