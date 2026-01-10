# mtr build targets

SHELL := /bin/bash
.SHELLFLAGS := -euo pipefail -c

# Include version definitions
include versions.mk

# Architecture (set by parent Makefile or default to host)
ARCH ?= amd64
ARCHS := amd64 arm64

# Docker configuration
DOCKER ?= docker
BUILDX ?= $(DOCKER) buildx

# Output directory
OUT_DIR ?= $(CURDIR)/../../dist
TOOL_OUT_DIR := $(OUT_DIR)/mtr

# Image name for intermediate builds
IMAGE_NAME := static-tools-mtr-builder

# Platform mapping
PLATFORM_amd64 := linux/amd64
PLATFORM_arm64 := linux/arm64

# Get Alpine digest for architecture
ALPINE_DIGEST_amd64 := $(ALPINE_DIGEST_AMD64)
ALPINE_DIGEST_arm64 := $(ALPINE_DIGEST_ARM64)

.PHONY: build
build: $(TOOL_OUT_DIR)/$(ARCH)/mtr $(TOOL_OUT_DIR)/$(ARCH)/mtr-packet

$(TOOL_OUT_DIR)/$(ARCH)/mtr $(TOOL_OUT_DIR)/$(ARCH)/mtr-packet: Dockerfile versions.mk
	@mkdir -p $(TOOL_OUT_DIR)/$(ARCH)
	$(BUILDX) build \
		--platform $(PLATFORM_$(ARCH)) \
		--build-arg ALPINE_VERSION=$(ALPINE_VERSION) \
		--build-arg ALPINE_DIGEST=$(ALPINE_DIGEST_$(ARCH)) \
		--build-arg MTR_VERSION=$(MTR_VERSION) \
		--build-arg MTR_SOURCE_SHA256=$(MTR_SOURCE_SHA256) \
		--output type=local,dest=$(TOOL_OUT_DIR)/$(ARCH) \
		--target export \
		.
	@echo "Built mtr $(MTR_VERSION) for $(ARCH):"
	@ls -la $(TOOL_OUT_DIR)/$(ARCH)/

# Build for all architectures
.PHONY: build-all
build-all:
	$(foreach arch,$(ARCHS),$(MAKE) build ARCH=$(arch);)

# Test the binary
.PHONY: test
test: build
	@echo "==> Testing mtr binary for $(ARCH)"
	@file $(TOOL_OUT_DIR)/$(ARCH)/mtr | grep -q "statically linked" || \
		(echo "ERROR: Binary is not statically linked" && exit 1)
	@echo "✓ Binary is statically linked"
	@# Run mtr --version in a minimal container
	$(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/mtr:/mtr:ro \
		alpine:$(ALPINE_VERSION) /mtr --version
	@echo "✓ Binary executes successfully"

# Clean build artifacts
.PHONY: clean
clean:
	rm -rf $(TOOL_OUT_DIR)

# Show versions
.PHONY: versions
versions:
	@echo "mtr version: $(MTR_VERSION)"
	@echo "mtr source SHA256: $(MTR_SOURCE_SHA256)"
	@echo "Alpine version: $(ALPINE_VERSION)"
	@echo "Alpine amd64 digest: $(ALPINE_DIGEST_AMD64)"
	@echo "Alpine arm64 digest: $(ALPINE_DIGEST_ARM64)"

.PHONY: help
help:
	@echo "mtr build targets:"
	@echo "  make build        Build mtr for ARCH (default: $(ARCH))"
	@echo "  make build-all    Build mtr for all architectures"
	@echo "  make test         Test the built binary"
	@echo "  make clean        Remove build artifacts"
	@echo "  make versions     Show pinned versions"
