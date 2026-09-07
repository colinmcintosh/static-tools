# iperf3 version and checksums
# All versions and checksums should be pinned for reproducibility

# iperf3 source
IPERF3_VERSION := 3.18
IPERF3_SOURCE_URL := https://github.com/esnet/iperf/releases/download/$(IPERF3_VERSION)/iperf-$(IPERF3_VERSION).tar.gz
IPERF3_SOURCE_SHA256 := c0618175514331e766522500e20c94bfb293b4424eb27d7207fb427b88d20bab

# Alpine base image (pinned by digest for reproducibility)
ALPINE_VERSION := 3.21
ALPINE_DIGEST_AMD64 := sha256:41c81533144786e0beb2b148667355a6c7659aa99a14ed837ff15a98ca9d71f3
ALPINE_DIGEST_ARM64 := sha256:fac2338de28c1143c0e69b48ba2d9b50481d5f1542b46c4656e5d6912d2d963a

# Image reference helper (use digest for the target architecture)
define alpine_image
alpine:$(ALPINE_VERSION)@$(if $(filter amd64,$(1)),$(ALPINE_DIGEST_AMD64),$(ALPINE_DIGEST_ARM64))
endef
