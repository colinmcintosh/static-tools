# zstd build targets

SHELL := /bin/bash
.SHELLFLAGS := -euo pipefail -c

# Include version definitions (reuses deps/versions.mk's zstd pin)
include versions.mk

# Architecture (set by parent Makefile or default to host)
ARCH ?= amd64
ARCHS := amd64 arm64

# Docker configuration
DOCKER ?= docker
BUILDX ?= $(DOCKER) buildx

# Output directory
OUT_DIR ?= $(CURDIR)/../../dist
TOOL_OUT_DIR := $(OUT_DIR)/zstd

# Platform mapping
PLATFORM_amd64 := linux/amd64
PLATFORM_arm64 := linux/arm64

# Get Alpine digest for architecture
ALPINE_DIGEST_amd64 := $(ALPINE_DIGEST_AMD64)
ALPINE_DIGEST_arm64 := $(ALPINE_DIGEST_ARM64)

.PHONY: build build-all test verify-static clean info

build: $(TOOL_OUT_DIR)/$(ARCH)/zstd

$(TOOL_OUT_DIR)/$(ARCH)/zstd: Dockerfile versions.mk
	@mkdir -p $(TOOL_OUT_DIR)/$(ARCH)
	$(BUILDX) build \
		--platform $(PLATFORM_$(ARCH)) \
		--build-arg BUILDER_IMAGE=$(BUILDER_IMAGE) \
		--build-arg BUILDER_DIGEST=$(BUILDER_DIGEST) \
		--build-arg ZSTD_VERSION=$(ZSTD_VERSION) \
		--build-arg ZSTD_URL=$(ZSTD_URL) \
		--build-arg ZSTD_SHA256=$(ZSTD_SHA256) \
		--output type=local,dest=$(TOOL_OUT_DIR)/$(ARCH) \
		--target export \
		.
	@echo "Built zstd $(ZSTD_VERSION) for $(ARCH):"
	@ls -la $(TOOL_OUT_DIR)/$(ARCH)/

# Build for all architectures
build-all:
	$(foreach arch,$(ARCHS),$(MAKE) build ARCH=$(arch);)

# Test the binary
test: build
	@echo "==> Testing zstd binary for $(ARCH)"
	@# Check if binary exists and is executable
	@test -x $(TOOL_OUT_DIR)/$(ARCH)/zstd || \
		(echo "ERROR: zstd binary not found or not executable" && exit 1)
	@echo "✓ zstd binary exists"
	@# Check static linking
	@$(CURDIR)/../../scripts/assert-static-elf.sh $(TOOL_OUT_DIR)/$(ARCH)/zstd
	@# Run zstd --version in a container (zero libraries present, proving
	@# true static linking)
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/zstd:/zstd:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST_$(ARCH)) /zstd --version 2>&1) && \
		echo "$$OUTPUT" | grep -qi "zstandard" || \
		(echo "ERROR: zstd --version failed: $$OUTPUT" && exit 1)
	@echo "✓ zstd --version works"
	@# Round-trip a small test string through compress and decompress
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/zstd:/zstd:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST_$(ARCH)) /bin/sh -c '\
			set -eu; \
			msg="the quick brown fox jumps over the lazy dog"; \
			out=$$(printf "%s" "$$msg" | /zstd -c | /zstd -dc); \
			if [ "$$out" = "$$msg" ]; then echo ROUNDTRIP_OK; else echo ROUNDTRIP_MISMATCH; fi \
		' 2>&1) && \
		echo "$$OUTPUT" | grep -q "ROUNDTRIP_OK" || \
		(echo "ERROR: zstd compress/decompress round-trip failed: $$OUTPUT" && exit 1)
	@echo "✓ zstd compress/decompress round-trip works"
	@echo "==> All zstd tests passed"

# Verify static linking
verify-static: build
	@echo "==> Checking zstd binary linking for $(ARCH)"
	@$(CURDIR)/../../scripts/assert-static-elf.sh $(TOOL_OUT_DIR)/$(ARCH)/zstd

# Clean build artifacts
clean:
	rm -rf $(TOOL_OUT_DIR)

info:
	@echo "Tool: zstd (Zstandard compression CLI)"
	@echo "Source: zstd $(ZSTD_VERSION)"
	@echo "URL: $(ZSTD_URL)"
	@echo "SHA256: $(ZSTD_SHA256)"
