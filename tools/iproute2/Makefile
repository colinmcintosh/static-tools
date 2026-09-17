# iproute2 build targets

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
TOOL_OUT_DIR := $(OUT_DIR)/iproute2
DEPS_PREFIX := $(OUT_DIR)/deps/$(ARCH)

# Image name for intermediate builds
IMAGE_NAME := static-tools-iproute2-builder

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
build: $(TOOL_OUT_DIR)/$(ARCH)/ip $(TOOL_OUT_DIR)/$(ARCH)/ss

$(TOOL_OUT_DIR)/$(ARCH)/ip $(TOOL_OUT_DIR)/$(ARCH)/ss &: Dockerfile versions.mk $(DEPS_PREFIX)/lib/libcap.a
	@mkdir -p $(TOOL_OUT_DIR)/$(ARCH)
	$(BUILDX) build \
		--platform $(PLATFORM_$(ARCH)) \
		--build-context deps=$(DEPS_PREFIX) \
		--build-arg BUILDER_IMAGE=$(BUILDER_IMAGE) \
		--build-arg BUILDER_DIGEST=$(BUILDER_DIGEST) \
		--build-arg IPROUTE2_VERSION=$(IPROUTE2_VERSION) \
		--build-arg IPROUTE2_SOURCE_SHA256=$(IPROUTE2_SOURCE_SHA256) \
		--output type=local,dest=$(TOOL_OUT_DIR)/$(ARCH) \
		--target export \
		.
	@echo "Built iproute2 $(IPROUTE2_VERSION) for $(ARCH):"
	@ls -la $(TOOL_OUT_DIR)/$(ARCH)/

$(DEPS_PREFIX)/lib/libcap.a:
	$(MAKE) -C $(CURDIR)/../../deps build ARCH=$(ARCH) OUT_DIR=$(OUT_DIR)

# Build for all architectures
.PHONY: build-all
build-all:
	$(foreach arch,$(ARCHS),$(MAKE) build ARCH=$(arch);)

# Test the binaries
.PHONY: test
test: build
	@echo "==> Testing ip binary for $(ARCH)"
	@test -x $(TOOL_OUT_DIR)/$(ARCH)/ip || \
		(echo "ERROR: ip binary not found or not executable" && exit 1)
	@echo "✓ ip binary exists"
	@$(CURDIR)/../../scripts/assert-static-elf.sh $(TOOL_OUT_DIR)/$(ARCH)/ip
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/ip:/ip:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST_$(ARCH)) /ip -V 2>&1) && \
		echo "$$OUTPUT" | grep -qi "iproute2" || \
		(echo "ERROR: ip -V failed: $$OUTPUT" && exit 1)
	@echo "✓ ip --version works"
	@# Plain `ip help` intentionally exits non-zero (it is iproute2's
	@# usage/error path, same as invalid arguments), so it cannot be used
	@# in a strict &&-chain like the other tools' --help checks. `ip addr
	@# show` is used instead: it exercises a real netlink round trip
	@# (not just argv parsing) and always succeeds even in a minimal,
	@# unprivileged container because the loopback interface always exists.
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/ip:/ip:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST_$(ARCH)) /ip addr show 2>&1) && \
		echo "$$OUTPUT" | grep -qi "LOOPBACK" || \
		(echo "ERROR: ip addr show failed: $$OUTPUT" && exit 1)
	@echo "✓ ip addr show works"
	@echo "==> Testing ss binary for $(ARCH)"
	@test -x $(TOOL_OUT_DIR)/$(ARCH)/ss || \
		(echo "ERROR: ss binary not found or not executable" && exit 1)
	@echo "✓ ss binary exists"
	@$(CURDIR)/../../scripts/assert-static-elf.sh $(TOOL_OUT_DIR)/$(ARCH)/ss
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/ss:/ss:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST_$(ARCH)) /ss --version 2>&1) && \
		echo "$$OUTPUT" | grep -qi "iproute2" || \
		(echo "ERROR: ss --version failed: $$OUTPUT" && exit 1)
	@echo "✓ ss --version works"
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/ss:/ss:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST_$(ARCH)) /ss --help 2>&1) && \
		echo "$$OUTPUT" | grep -qi "usage" || \
		(echo "ERROR: ss --help failed" && exit 1)
	@echo "✓ ss --help works"
	@echo "==> All iproute2 tests passed"

# Clean build artifacts
.PHONY: clean
clean:
	rm -rf $(TOOL_OUT_DIR)

# Show versions
.PHONY: versions
versions:
	@echo "iproute2 version: $(IPROUTE2_VERSION)"
	@echo "iproute2 source SHA256: $(IPROUTE2_SOURCE_SHA256)"
	@echo "Alpine version: $(ALPINE_VERSION)"
	@echo "Alpine amd64 digest: $(ALPINE_DIGEST_AMD64)"
	@echo "Alpine arm64 digest: $(ALPINE_DIGEST_ARM64)"

.PHONY: help
help:
	@echo "iproute2 build targets:"
	@echo "  make build        Build ip and ss for ARCH (default: $(ARCH))"
	@echo "  make build-all    Build ip and ss for all architectures"
	@echo "  make test         Test the built binaries"
	@echo "  make clean        Remove build artifacts"
	@echo "  make versions     Show pinned versions"
