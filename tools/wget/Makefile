# wget build targets

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
TOOL_OUT_DIR := $(OUT_DIR)/wget

# Image name for intermediate builds
IMAGE_NAME := static-tools-wget-builder

# Platform mapping
PLATFORM_amd64 := linux/amd64
PLATFORM_arm64 := linux/arm64

# Get Alpine digest for architecture
ALPINE_DIGEST_amd64 := $(ALPINE_DIGEST_AMD64)
ALPINE_DIGEST_arm64 := $(ALPINE_DIGEST_ARM64)

.PHONY: build
build: $(TOOL_OUT_DIR)/$(ARCH)/wget

$(TOOL_OUT_DIR)/$(ARCH)/wget: Dockerfile versions.mk
	@mkdir -p $(TOOL_OUT_DIR)/$(ARCH)
	$(BUILDX) build \
		--platform $(PLATFORM_$(ARCH)) \
		--build-arg ALPINE_VERSION=$(ALPINE_VERSION) \
		--build-arg ALPINE_DIGEST=$(ALPINE_DIGEST_$(ARCH)) \
		--build-arg WGET_VERSION=$(WGET_VERSION) \
		--build-arg WGET_SOURCE_SHA256=$(WGET_SOURCE_SHA256) \
		--output type=local,dest=$(TOOL_OUT_DIR)/$(ARCH) \
		--target export \
		.
	@echo "Built wget $(WGET_VERSION) for $(ARCH):"
	@ls -la $(TOOL_OUT_DIR)/$(ARCH)/

# Build for all architectures
.PHONY: build-all
build-all:
	$(foreach arch,$(ARCHS),$(MAKE) build ARCH=$(arch);)

# Test the binary
.PHONY: test
test: build
	@echo "==> Testing wget binary for $(ARCH)"
	@# Check if binary exists and is executable
	@test -x $(TOOL_OUT_DIR)/$(ARCH)/wget || \
		(echo "ERROR: wget binary not found or not executable" && exit 1)
	@echo "✓ wget binary exists"
	@# Check static linking
	@file $(TOOL_OUT_DIR)/$(ARCH)/wget | grep -q "statically linked" || \
		(echo "ERROR: Binary is not statically linked" && exit 1)
	@echo "✓ wget binary is statically linked"

# Verify static linking
.PHONY: verify-static
verify-static: build
	@echo "==> Checking wget binary linking for $(ARCH)"
	@file $(TOOL_OUT_DIR)/$(ARCH)/wget

# Clean build artifacts
.PHONY: clean
clean:
	rm -rf $(TOOL_OUT_DIR)

.PHONY: info
info:
	@echo "Tool: wget (network file retriever)"
	@echo "Source: wget $(WGET_VERSION)"
	@echo "URL: $(WGET_SOURCE_URL)"
	@echo "SHA256: $(WGET_SOURCE_SHA256)"
