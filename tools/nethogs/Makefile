# nethogs build targets

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
TOOL_OUT_DIR := $(OUT_DIR)/nethogs
DEPS_PREFIX := $(OUT_DIR)/deps/$(ARCH)

# Image name for intermediate builds
IMAGE_NAME := static-tools-nethogs-builder

# Platform mapping
PLATFORM_amd64 := linux/amd64
PLATFORM_arm64 := linux/arm64

# Get Alpine digest for architecture
ALPINE_DIGEST_amd64 := $(ALPINE_DIGEST_AMD64)
ALPINE_DIGEST_arm64 := $(ALPINE_DIGEST_ARM64)

.PHONY: deps
deps:
	$(MAKE) -C $(CURDIR)/../../deps build ARCH=$(ARCH) OUT_DIR=$(OUT_DIR)

.PHONY: build
build: $(TOOL_OUT_DIR)/$(ARCH)/nethogs

$(TOOL_OUT_DIR)/$(ARCH)/nethogs: Dockerfile versions.mk $(DEPS_PREFIX)/lib/libpcap.a
	@mkdir -p $(TOOL_OUT_DIR)/$(ARCH)
	$(BUILDX) build \
		--platform $(PLATFORM_$(ARCH)) \
		--build-context deps=$(DEPS_PREFIX) \
		--build-arg BUILDER_IMAGE=$(BUILDER_IMAGE) \
		--build-arg BUILDER_DIGEST=$(BUILDER_DIGEST) \
		--build-arg NETHOGS_VERSION=$(NETHOGS_VERSION) \
		--build-arg NETHOGS_SOURCE_SHA256=$(NETHOGS_SOURCE_SHA256) \
		--output type=local,dest=$(TOOL_OUT_DIR)/$(ARCH) \
		--target export \
		.
	@echo "Built nethogs $(NETHOGS_VERSION) for $(ARCH):"
	@ls -la $(TOOL_OUT_DIR)/$(ARCH)/

$(DEPS_PREFIX)/lib/libpcap.a $(DEPS_PREFIX)/lib/libncursesw.a &:
	$(MAKE) -C $(CURDIR)/../../deps build ARCH=$(ARCH) OUT_DIR=$(OUT_DIR)

# Build for all architectures
.PHONY: build-all
build-all:
	$(foreach arch,$(ARCHS),$(MAKE) build ARCH=$(arch);)

# Test the binary
.PHONY: test
test: build
	@echo "==> Testing nethogs binary for $(ARCH)"
	@# Check if binary exists and is executable
	@test -x $(TOOL_OUT_DIR)/$(ARCH)/nethogs || \
		(echo "ERROR: nethogs binary not found or not executable" && exit 1)
	@echo "✓ nethogs binary exists"
	@# Check static linking
	@$(CURDIR)/../../scripts/assert-static-elf.sh $(TOOL_OUT_DIR)/$(ARCH)/nethogs
	@# Run nethogs -V (version) in a throwaway container with zero libraries,
	@# which proves the binary is genuinely statically linked.
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/nethogs:/nethogs:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST_$(ARCH)) /nethogs -V 2>&1) && \
		echo "$$OUTPUT" | grep -q "$(NETHOGS_VERSION)" || \
		(echo "ERROR: nethogs -V failed: $$OUTPUT" && exit 1)
	@echo "✓ nethogs -V works"
	@# Run nethogs -h (help) in a container
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/nethogs:/nethogs:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST_$(ARCH)) /nethogs -h 2>&1) && \
		echo "$$OUTPUT" | grep -qi "usage" || \
		(echo "ERROR: nethogs -h failed: $$OUTPUT" && exit 1)
	@echo "✓ nethogs -h works"
	@echo "==> All nethogs tests passed"

# Verify static linking
.PHONY: verify-static
verify-static: build
	@echo "==> Checking nethogs binary linking for $(ARCH)"
	@$(CURDIR)/../../scripts/assert-static-elf.sh $(TOOL_OUT_DIR)/$(ARCH)/nethogs

# Clean build artifacts
.PHONY: clean
clean:
	rm -rf $(TOOL_OUT_DIR)

.PHONY: info
info:
	@echo "Tool: nethogs (per-process bandwidth monitor)"
	@echo "Source: nethogs $(NETHOGS_VERSION)"
	@echo "URL: $(NETHOGS_SOURCE_URL)"
	@echo "SHA256: $(NETHOGS_SOURCE_SHA256)"
