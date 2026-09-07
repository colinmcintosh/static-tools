# rsync build targets

SHELL := /bin/bash
.SHELLFLAGS := -euo pipefail -c

include versions.mk

ARCH ?= amd64
ARCHS := amd64 arm64

DOCKER ?= docker
BUILDX ?= $(DOCKER) buildx

OUT_DIR ?= $(CURDIR)/../../dist
TOOL_OUT_DIR := $(OUT_DIR)/rsync
DEPS_PREFIX := $(OUT_DIR)/deps/$(ARCH)

PLATFORM_amd64 := linux/amd64
PLATFORM_arm64 := linux/arm64

ALPINE_DIGEST_amd64 := $(ALPINE_DIGEST_AMD64)
ALPINE_DIGEST_arm64 := $(ALPINE_DIGEST_ARM64)

.PHONY: deps
deps:
	$(MAKE) -C $(CURDIR)/../../deps build ARCH=$(ARCH) OUT_DIR=$(OUT_DIR)

.PHONY: build
build: $(TOOL_OUT_DIR)/$(ARCH)/rsync

$(TOOL_OUT_DIR)/$(ARCH)/rsync: Dockerfile versions.mk $(DEPS_PREFIX)/lib/libzstd.a
	@mkdir -p $(TOOL_OUT_DIR)/$(ARCH)
	$(BUILDX) build \
		--platform $(PLATFORM_$(ARCH)) \
		--build-context deps=$(DEPS_PREFIX) \
		--build-arg ALPINE_VERSION=$(ALPINE_VERSION) \
		--build-arg ALPINE_DIGEST=$(ALPINE_DIGEST_$(ARCH)) \
		--build-arg RSYNC_VERSION=$(RSYNC_VERSION) \
		--build-arg RSYNC_SOURCE_SHA256=$(RSYNC_SOURCE_SHA256) \
		--output type=local,dest=$(TOOL_OUT_DIR)/$(ARCH) \
		--target export \
		.
	@echo "Built rsync $(RSYNC_VERSION) for $(ARCH):"
	@ls -la $(TOOL_OUT_DIR)/$(ARCH)/

$(DEPS_PREFIX)/lib/libzstd.a:
	$(MAKE) -C $(CURDIR)/../../deps build ARCH=$(ARCH) OUT_DIR=$(OUT_DIR)

.PHONY: build-all
build-all:
	$(foreach arch,$(ARCHS),$(MAKE) build ARCH=$(arch);)

.PHONY: test
test: build
	@echo "==> Testing rsync binary for $(ARCH)"
	@test -x $(TOOL_OUT_DIR)/$(ARCH)/rsync || \
		(echo "ERROR: rsync binary not found or not executable" && exit 1)
	@echo "✓ rsync binary exists"
	@file $(TOOL_OUT_DIR)/$(ARCH)/rsync | grep -q "statically linked" || \
		(echo "ERROR: Binary is not statically linked" && exit 1)
	@echo "✓ rsync binary is statically linked"
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/rsync:/rsync:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST_$(ARCH)) /rsync --version 2>&1); \
		echo "$$OUTPUT" | grep -qi "rsync" || \
		(echo "ERROR: rsync --version failed: $$OUTPUT" && exit 1); \
		echo "$$OUTPUT" | grep -qi "xxhash" || \
		(echo "ERROR: rsync --version missing xxhash: $$OUTPUT" && exit 1); \
		echo "$$OUTPUT" | grep -qi "zstd" || \
		(echo "ERROR: rsync --version missing zstd: $$OUTPUT" && exit 1); \
		echo "$$OUTPUT" | grep -qi "lz4" || \
		(echo "ERROR: rsync --version missing lz4: $$OUTPUT" && exit 1); \
		echo "$$OUTPUT" | grep -qi "openssl" || \
		(echo "ERROR: rsync --version missing openssl: $$OUTPUT" && exit 1)
	@echo "✓ rsync --version reports xxhash/zstd/lz4/openssl"
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/rsync:/rsync:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST_$(ARCH)) /rsync --help 2>&1) && \
		echo "$$OUTPUT" | grep -qi "usage" || \
		(echo "ERROR: rsync --help failed: $$OUTPUT" && exit 1)
	@echo "✓ rsync --help works"
	@$(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/rsync:/rsync:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST_$(ARCH)) \
		/bin/sh -c 'printf hello > /tmp/src && mkdir /tmp/dst && /rsync -a /tmp/src /tmp/dst/ && grep -q hello /tmp/dst/src' || \
		(echo "ERROR: rsync file copy failed" && exit 1)
	@echo "✓ rsync file copy works"
	@echo "==> All rsync tests passed"

.PHONY: verify-static
verify-static: build
	@echo "==> Checking rsync binary linking for $(ARCH)"
	@file $(TOOL_OUT_DIR)/$(ARCH)/rsync

.PHONY: clean
clean:
	rm -rf $(TOOL_OUT_DIR)

.PHONY: info
info:
	@echo "Tool: rsync (file-copying tool)"
	@echo "Source: rsync $(RSYNC_VERSION)"
	@echo "URL: $(RSYNC_SOURCE_URL)"
	@echo "SHA256: $(RSYNC_SOURCE_SHA256)"
