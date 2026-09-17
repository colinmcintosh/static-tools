# nmap build targets

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
TOOL_OUT_DIR := $(OUT_DIR)/nmap
DEPS_PREFIX := $(OUT_DIR)/deps/$(ARCH)

# Image name for intermediate builds
IMAGE_NAME := static-tools-nmap-builder

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
build: $(TOOL_OUT_DIR)/$(ARCH)/nmap $(TOOL_OUT_DIR)/$(ARCH)/nmap-services

$(TOOL_OUT_DIR)/$(ARCH)/nmap $(TOOL_OUT_DIR)/$(ARCH)/nmap-services &: Dockerfile versions.mk $(DEPS_PREFIX)/lib/libssl.a $(DEPS_PREFIX)/lib/libpcap.a
	@mkdir -p $(TOOL_OUT_DIR)/$(ARCH)
	$(BUILDX) build \
		--platform $(PLATFORM_$(ARCH)) \
		--build-context deps=$(DEPS_PREFIX) \
		--build-arg BUILDER_IMAGE=$(BUILDER_IMAGE) \
		--build-arg BUILDER_DIGEST=$(BUILDER_DIGEST) \
		--build-arg NMAP_VERSION=$(NMAP_VERSION) \
		--build-arg NMAP_SOURCE_SHA256=$(NMAP_SOURCE_SHA256) \
		--output type=local,dest=$(TOOL_OUT_DIR)/$(ARCH) \
		--target export \
		.
	@echo "Built nmap $(NMAP_VERSION) for $(ARCH):"
	@ls -la $(TOOL_OUT_DIR)/$(ARCH)/

$(DEPS_PREFIX)/lib/libssl.a $(DEPS_PREFIX)/lib/libpcap.a &:
	$(MAKE) -C $(CURDIR)/../../deps build ARCH=$(ARCH) OUT_DIR=$(OUT_DIR)

# Build for all architectures
.PHONY: build-all
build-all:
	$(foreach arch,$(ARCHS),$(MAKE) build ARCH=$(arch);)

# Test the binary
.PHONY: test
test: build
	@echo "==> Testing nmap binary for $(ARCH)"
	@# Check if binary exists and is executable
	@test -x $(TOOL_OUT_DIR)/$(ARCH)/nmap || \
		(echo "ERROR: nmap binary not found or not executable" && exit 1)
	@echo "✓ nmap binary exists"
	@test -f $(TOOL_OUT_DIR)/$(ARCH)/nmap-services || \
		(echo "ERROR: nmap-services not found" && exit 1)
	@echo "✓ nmap-services exists"
	@# Check static linking
	@$(CURDIR)/../../scripts/assert-static-elf.sh $(TOOL_OUT_DIR)/$(ARCH)/nmap
	@# Run nmap --version in a container (zero libraries present, proves static linking)
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/nmap:/nmap:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST_$(ARCH)) /nmap --version 2>&1) && \
		echo "$$OUTPUT" | grep -qi "Nmap version" || \
		(echo "ERROR: nmap --version failed: $$OUTPUT" && exit 1)
	@echo "✓ nmap --version works"
	@# Run nmap -h in a container
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/nmap:/nmap:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST_$(ARCH)) /nmap -h 2>&1) && \
		echo "$$OUTPUT" | grep -qi "usage" || \
		(echo "ERROR: nmap -h failed" && exit 1)
	@echo "✓ nmap -h works"
	@# Run a real TCP-connect scan against loopback with a listener on the
	@# scanned port, so the result is a deterministic "open" rather than
	@# depending on nothing else listening in the container. -sT needs no
	@# raw sockets/root, unlike -sS. nmap-services ships next to the binary;
	@# nmap auto-discovers data files next to its own executable, so the
	@# service name (http) should resolve without --datadir/NMAPDIR. All
	@# three checks share one shell invocation so $$OUTPUT stays in scope.
	@OUTPUT=$$($(DOCKER) run --rm --network none --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/nmap:/nmap:ro \
		-v $(TOOL_OUT_DIR)/$(ARCH)/nmap-services:/nmap-services:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST_$(ARCH)) \
		/bin/sh -c 'nc -l -p 80 >/dev/null 2>&1 & sleep 1; /nmap -sT -p 80 127.0.0.1' 2>&1) && \
		(echo "$$OUTPUT" | grep -qi "Nmap done" || \
			(echo "ERROR: nmap -sT scan failed: $$OUTPUT" && exit 1)) && \
		(echo "$$OUTPUT" | grep -qi "80/tcp *open" || \
			(echo "ERROR: nmap did not report the listening port as open: $$OUTPUT" && exit 1)) && \
		(echo "$$OUTPUT" | grep -qi "80/tcp *open *http" || \
			(echo "ERROR: nmap-services service-name lookup failed: $$OUTPUT" && exit 1))
	@echo "✓ nmap -sT TCP connect scan works and reports open ports"
	@echo "✓ nmap-services next to the binary is used automatically"
	@echo "==> All nmap tests passed"

# Verify static linking
.PHONY: verify-static
verify-static: build
	@echo "==> Checking nmap binary linking for $(ARCH)"
	@$(CURDIR)/../../scripts/assert-static-elf.sh $(TOOL_OUT_DIR)/$(ARCH)/nmap

# Clean build artifacts
.PHONY: clean
clean:
	rm -rf $(TOOL_OUT_DIR)

.PHONY: info
info:
	@echo "Tool: nmap (network discovery and security auditing)"
	@echo "Source: nmap $(NMAP_VERSION)"
	@echo "URL: $(NMAP_SOURCE_URL)"
	@echo "SHA256: $(NMAP_SOURCE_SHA256)"
