# tcpdump build targets

SHELL := /bin/bash
.SHELLFLAGS := -euo pipefail -c

include versions.mk

ARCH ?= amd64
ARCHS := amd64 arm64

DOCKER ?= docker
BUILDX ?= $(DOCKER) buildx

OUT_DIR ?= $(CURDIR)/../../dist
TOOL_OUT_DIR := $(OUT_DIR)/tcpdump
DEPS_PREFIX := $(OUT_DIR)/deps/$(ARCH)

PLATFORM_amd64 := linux/amd64
PLATFORM_arm64 := linux/arm64

ALPINE_DIGEST_amd64 := $(ALPINE_DIGEST_AMD64)
ALPINE_DIGEST_arm64 := $(ALPINE_DIGEST_ARM64)

.PHONY: deps
deps:
	$(MAKE) -C $(CURDIR)/../../deps build ARCH=$(ARCH) OUT_DIR=$(OUT_DIR)

.PHONY: build
build: $(TOOL_OUT_DIR)/$(ARCH)/tcpdump

$(TOOL_OUT_DIR)/$(ARCH)/tcpdump: Dockerfile versions.mk $(DEPS_PREFIX)/lib/libpcap.a
	@mkdir -p $(TOOL_OUT_DIR)/$(ARCH)
	$(BUILDX) build \
		--platform $(PLATFORM_$(ARCH)) \
		--build-context deps=$(DEPS_PREFIX) \
		--build-arg ALPINE_VERSION=$(ALPINE_VERSION) \
		--build-arg ALPINE_DIGEST=$(ALPINE_DIGEST_$(ARCH)) \
		--build-arg TCPDUMP_VERSION=$(TCPDUMP_VERSION) \
		--build-arg TCPDUMP_SOURCE_SHA256=$(TCPDUMP_SOURCE_SHA256) \
		--output type=local,dest=$(TOOL_OUT_DIR)/$(ARCH) \
		--target export \
		.
	@echo "Built tcpdump $(TCPDUMP_VERSION) for $(ARCH):"
	@ls -la $(TOOL_OUT_DIR)/$(ARCH)/

$(DEPS_PREFIX)/lib/libpcap.a:
	$(MAKE) -C $(CURDIR)/../../deps build ARCH=$(ARCH) OUT_DIR=$(OUT_DIR)

.PHONY: build-all
build-all:
	$(foreach arch,$(ARCHS),$(MAKE) build ARCH=$(arch);)

.PHONY: test
test: build
	@echo "==> Testing tcpdump binary for $(ARCH)"
	@test -x $(TOOL_OUT_DIR)/$(ARCH)/tcpdump || \
		(echo "ERROR: tcpdump binary not found or not executable" && exit 1)
	@echo "✓ tcpdump binary exists"
	@file $(TOOL_OUT_DIR)/$(ARCH)/tcpdump | grep -q "statically linked" || \
		(echo "ERROR: Binary is not statically linked" && exit 1)
	@echo "✓ tcpdump binary is statically linked"
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/tcpdump:/tcpdump:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST_$(ARCH)) /tcpdump --version 2>&1) && \
		echo "$$OUTPUT" | grep -qi "tcpdump" || \
		(echo "ERROR: tcpdump --version failed: $$OUTPUT" && exit 1)
	@echo "✓ tcpdump --version works"
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/tcpdump:/tcpdump:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST_$(ARCH)) /tcpdump --help 2>&1) && \
		echo "$$OUTPUT" | grep -qi "usage" || \
		(echo "ERROR: tcpdump --help failed: $$OUTPUT" && exit 1)
	@echo "✓ tcpdump --help works"
	@echo "==> All tcpdump tests passed"

.PHONY: verify-static
verify-static: build
	@echo "==> Checking tcpdump binary linking for $(ARCH)"
	@file $(TOOL_OUT_DIR)/$(ARCH)/tcpdump

.PHONY: clean
clean:
	rm -rf $(TOOL_OUT_DIR)

.PHONY: info
info:
	@echo "Tool: tcpdump (packet analyzer)"
	@echo "Source: tcpdump $(TCPDUMP_VERSION)"
	@echo "URL: $(TCPDUMP_SOURCE_URL)"
	@echo "SHA256: $(TCPDUMP_SOURCE_SHA256)"
