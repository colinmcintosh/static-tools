# less build targets

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
TOOL_OUT_DIR := $(OUT_DIR)/less
DEPS_PREFIX := $(OUT_DIR)/deps/$(ARCH)

# Image name for intermediate builds
IMAGE_NAME := static-tools-less-builder

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
build: $(TOOL_OUT_DIR)/$(ARCH)/less

$(TOOL_OUT_DIR)/$(ARCH)/less: Dockerfile versions.mk $(DEPS_PREFIX)/lib/libncursesw.a
	@mkdir -p $(TOOL_OUT_DIR)/$(ARCH)
	$(BUILDX) build \
		--platform $(PLATFORM_$(ARCH)) \
		--build-context deps=$(DEPS_PREFIX) \
		--build-arg BUILDER_IMAGE=$(BUILDER_IMAGE) \
		--build-arg BUILDER_DIGEST=$(BUILDER_DIGEST) \
		--build-arg LESS_VERSION=$(LESS_VERSION) \
		--build-arg LESS_SOURCE_URL=$(LESS_SOURCE_URL) \
		--build-arg LESS_SOURCE_SHA256=$(LESS_SOURCE_SHA256) \
		--output type=local,dest=$(TOOL_OUT_DIR)/$(ARCH) \
		--target export \
		.
	@echo "Built less $(LESS_VERSION) for $(ARCH):"
	@ls -la $(TOOL_OUT_DIR)/$(ARCH)/

$(DEPS_PREFIX)/lib/libncursesw.a:
	$(MAKE) -C $(CURDIR)/../../deps build ARCH=$(ARCH) OUT_DIR=$(OUT_DIR)

# Build for all architectures
.PHONY: build-all
build-all:
	$(foreach arch,$(ARCHS),$(MAKE) build ARCH=$(arch);)

# Test the binary
.PHONY: test
test: build
	@echo "==> Testing less binary for $(ARCH)"
	@# Check if binary exists and is executable
	@test -x $(TOOL_OUT_DIR)/$(ARCH)/less || \
		(echo "ERROR: less binary not found or not executable" && exit 1)
	@echo "✓ less binary exists"
	@# Check static linking
	@$(CURDIR)/../../scripts/assert-static-elf.sh $(TOOL_OUT_DIR)/$(ARCH)/less
	@# Run less --version in a container (zero libraries present: proves
	@# the binary is truly self-contained, not just statically-linked-ish)
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/less:/less:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST_$(ARCH)) /less --version 2>&1) && \
		echo "$$OUTPUT" | grep -qi "less" || \
		(echo "ERROR: less --version failed: $$OUTPUT" && exit 1)
	@echo "✓ less --version works"
	@# Run less --help in a container. --help prints the built-in help
	@# screen, whose section headers (e.g. "SUMMARY OF LESS COMMANDS") are
	@# bold-by-doubling every letter (nroff-style overstrike), so match on
	@# plain-case body text instead of a header.
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/less:/less:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST_$(ARCH)) /less --help 2>&1) && \
		echo "$$OUTPUT" | grep -qi "forward\|backward" || \
		(echo "ERROR: less --help failed: $$OUTPUT" && exit 1)
	@echo "✓ less --help works"
	@# Pipe a short line of text through less non-interactively. -F
	@# (--quit-if-one-screen) makes less write the input and exit as soon
	@# as it knows the content fits on one screen, without ever opening
	@# /dev/tty for keyboard input; -X skips the termcap init/deinit
	@# sequences, which also sidesteps needing a real terminfo database.
	@# `timeout` is a backstop in case some environment still blocks on
	@# tty access despite those flags.
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/less:/less:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST_$(ARCH)) \
		/bin/sh -c 'printf "hello from less\n" | timeout 5 /less -F -X' 2>&1) && \
		echo "$$OUTPUT" | grep -q "hello from less" || \
		(echo "ERROR: less -F -X non-interactive pipe test failed: $$OUTPUT" && exit 1)
	@echo "✓ less non-interactive pipe test works"
	@echo "==> All less tests passed"

# Verify static linking
.PHONY: verify-static
verify-static: build
	@echo "==> Checking less binary linking for $(ARCH)"
	@$(CURDIR)/../../scripts/assert-static-elf.sh $(TOOL_OUT_DIR)/$(ARCH)/less

# Clean build artifacts
.PHONY: clean
clean:
	rm -rf $(TOOL_OUT_DIR)

.PHONY: info
info:
	@echo "Tool: less (terminal pager)"
	@echo "Source: less $(LESS_VERSION)"
	@echo "URL: $(LESS_SOURCE_URL)"
	@echo "SHA256: $(LESS_SOURCE_SHA256)"
