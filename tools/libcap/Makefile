# libcap build targets (getcap, setcap)

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
TOOL_OUT_DIR := $(OUT_DIR)/libcap
DEPS_PREFIX := $(OUT_DIR)/deps/$(ARCH)

# Image name for intermediate builds
IMAGE_NAME := static-tools-libcap-builder

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
build: $(TOOL_OUT_DIR)/$(ARCH)/getcap $(TOOL_OUT_DIR)/$(ARCH)/setcap

$(TOOL_OUT_DIR)/$(ARCH)/getcap $(TOOL_OUT_DIR)/$(ARCH)/setcap &: Dockerfile versions.mk $(DEPS_PREFIX)/lib/libcap.a
	@mkdir -p $(TOOL_OUT_DIR)/$(ARCH)
	$(BUILDX) build \
		--platform $(PLATFORM_$(ARCH)) \
		--build-context deps=$(DEPS_PREFIX) \
		--build-arg BUILDER_IMAGE=$(BUILDER_IMAGE) \
		--build-arg BUILDER_DIGEST=$(BUILDER_DIGEST) \
		--build-arg LIBCAP_VERSION=$(LIBCAP_VERSION) \
		--build-arg LIBCAP_URL=$(LIBCAP_URL) \
		--build-arg LIBCAP_SHA256=$(LIBCAP_SHA256) \
		--output type=local,dest=$(TOOL_OUT_DIR)/$(ARCH) \
		--target export \
		.
	@echo "Built libcap $(LIBCAP_VERSION) (getcap, setcap) for $(ARCH):"
	@ls -la $(TOOL_OUT_DIR)/$(ARCH)/

$(DEPS_PREFIX)/lib/libcap.a &:
	$(MAKE) -C $(CURDIR)/../../deps build ARCH=$(ARCH) OUT_DIR=$(OUT_DIR)

# Build for all architectures
.PHONY: build-all
build-all:
	$(foreach arch,$(ARCHS),$(MAKE) build ARCH=$(arch);)

# Test the binaries
.PHONY: test
test: build
	@echo "==> Testing getcap binary for $(ARCH)"
	@test -x $(TOOL_OUT_DIR)/$(ARCH)/getcap || \
		(echo "ERROR: getcap binary not found or not executable" && exit 1)
	@echo "✓ getcap binary exists"
	@$(CURDIR)/../../scripts/assert-static-elf.sh $(TOOL_OUT_DIR)/$(ARCH)/getcap
	@echo "==> Testing setcap binary for $(ARCH)"
	@test -x $(TOOL_OUT_DIR)/$(ARCH)/setcap || \
		(echo "ERROR: setcap binary not found or not executable" && exit 1)
	@echo "✓ setcap binary exists"
	@$(CURDIR)/../../scripts/assert-static-elf.sh $(TOOL_OUT_DIR)/$(ARCH)/setcap
	@echo "==> Testing getcap -h works (zero-library alpine container)"
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/getcap:/getcap:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST_$(ARCH)) /getcap -h 2>&1) && \
		echo "$$OUTPUT" | grep -qi "usage" || \
		(echo "ERROR: getcap -h failed: $$OUTPUT" && exit 1)
	@echo "✓ getcap -h works"
	@echo "==> Testing setcap -h works (zero-library alpine container)"
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/setcap:/setcap:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST_$(ARCH)) /setcap -h 2>&1) && \
		echo "$$OUTPUT" | grep -qi "usage" || \
		(echo "ERROR: setcap -h failed: $$OUTPUT" && exit 1)
	@echo "✓ setcap -h works"
	@echo "==> Testing setcap/getcap capability round-trip (zero-library alpine container)"
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/getcap:/getcap:ro \
		-v $(TOOL_OUT_DIR)/$(ARCH)/setcap:/setcap:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST_$(ARCH)) \
		/bin/sh -c 'touch /tmp/capfile && /setcap cap_net_raw+ep /tmp/capfile && /getcap /tmp/capfile' 2>&1) && \
		echo "$$OUTPUT" | grep -qi "cap_net_raw" || \
		(echo "ERROR: setcap/getcap round-trip failed: $$OUTPUT" && exit 1)
	@echo "✓ setcap/getcap round-trip works (setcap wrote a capability, getcap read it back)"
	@echo "==> All libcap tests passed"

# Clean build artifacts
.PHONY: clean
clean:
	rm -rf $(TOOL_OUT_DIR)

# Show versions
.PHONY: versions
versions:
	@echo "libcap version: $(LIBCAP_VERSION)"
	@echo "libcap source SHA256: $(LIBCAP_SHA256)"
	@echo "Alpine version: $(ALPINE_VERSION)"
	@echo "Alpine amd64 digest: $(ALPINE_DIGEST_AMD64)"
	@echo "Alpine arm64 digest: $(ALPINE_DIGEST_ARM64)"

.PHONY: help
help:
	@echo "libcap build targets:"
	@echo "  make build        Build getcap/setcap for ARCH (default: $(ARCH))"
	@echo "  make build-all    Build getcap/setcap for all architectures"
	@echo "  make test         Test the built binaries"
	@echo "  make clean        Remove build artifacts"
	@echo "  make versions     Show pinned versions"
