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
DEPS_PREFIX := $(OUT_DIR)/deps/$(ARCH)

# Image name for intermediate builds
IMAGE_NAME := static-tools-mtr-builder

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
build: $(TOOL_OUT_DIR)/$(ARCH)/mtr $(TOOL_OUT_DIR)/$(ARCH)/mtr-packet

$(TOOL_OUT_DIR)/$(ARCH)/mtr $(TOOL_OUT_DIR)/$(ARCH)/mtr-packet &: Dockerfile versions.mk $(DEPS_PREFIX)/lib/libncursesw.a
	@mkdir -p $(TOOL_OUT_DIR)/$(ARCH)
	$(BUILDX) build \
		--platform $(PLATFORM_$(ARCH)) \
		--build-context deps=$(DEPS_PREFIX) \
		--build-arg ALPINE_VERSION=$(ALPINE_VERSION) \
		--build-arg ALPINE_DIGEST=$(ALPINE_DIGEST_$(ARCH)) \
		--build-arg MTR_VERSION=$(MTR_VERSION) \
		--build-arg MTR_SOURCE_SHA256=$(MTR_SOURCE_SHA256) \
		--output type=local,dest=$(TOOL_OUT_DIR)/$(ARCH) \
		--target export \
		.
	@echo "Built mtr $(MTR_VERSION) for $(ARCH):"
	@ls -la $(TOOL_OUT_DIR)/$(ARCH)/

$(DEPS_PREFIX)/lib/libncursesw.a $(DEPS_PREFIX)/lib/libssl.a &:
	$(MAKE) -C $(CURDIR)/../../deps build ARCH=$(ARCH) OUT_DIR=$(OUT_DIR)

# Build for all architectures
.PHONY: build-all
build-all:
	$(foreach arch,$(ARCHS),$(MAKE) build ARCH=$(arch);)

# Test the binaries
.PHONY: test
test: build
	@echo "==> Testing mtr binary for $(ARCH)"
	@test -x $(TOOL_OUT_DIR)/$(ARCH)/mtr || \
		(echo "ERROR: mtr binary not found or not executable" && exit 1)
	@echo "✓ mtr binary exists"
	@$(CURDIR)/../../scripts/assert-static-elf.sh $(TOOL_OUT_DIR)/$(ARCH)/mtr
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/mtr:/mtr:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST_$(ARCH)) /mtr --version 2>&1) && \
		echo "$$OUTPUT" | grep -q "mtr" || \
		(echo "ERROR: mtr --version failed" && exit 1)
	@echo "✓ mtr --version works"
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/mtr:/mtr:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST_$(ARCH)) /mtr --help 2>&1) && \
		echo "$$OUTPUT" | grep -qi "usage\|options\|hostname" || \
		(echo "ERROR: mtr --help failed" && exit 1)
	@echo "✓ mtr --help works"
	@echo "==> Testing mtr-packet binary for $(ARCH)"
	@test -x $(TOOL_OUT_DIR)/$(ARCH)/mtr-packet || \
		(echo "ERROR: mtr-packet binary not found or not executable" && exit 1)
	@echo "✓ mtr-packet binary exists"
	@$(CURDIR)/../../scripts/assert-static-elf.sh $(TOOL_OUT_DIR)/$(ARCH)/mtr-packet
	@# mtr-packet is a stdin protocol helper (no --version/--help flags).
	@# --version equivalent: check-support feature version
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/mtr-packet:/mtr-packet:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST_$(ARCH)) \
		/bin/sh -c 'printf "1 check-support feature version\n" | /mtr-packet' 2>&1) && \
		echo "$$OUTPUT" | grep -qi "version\|feature-support\|support" || \
		(echo "ERROR: mtr-packet version check failed: $$OUTPUT" && exit 1)
	@echo "✓ mtr-packet --version works"
	@# --help equivalent: check-support for a documented command
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/mtr-packet:/mtr-packet:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST_$(ARCH)) \
		/bin/sh -c 'printf "1 check-support feature send-probe\n" | /mtr-packet' 2>&1) && \
		echo "$$OUTPUT" | grep -qi "support\|feature\|send-probe" || \
		(echo "ERROR: mtr-packet --help failed: $$OUTPUT" && exit 1)
	@echo "✓ mtr-packet --help works"
	@echo "==> All mtr tests passed"

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
