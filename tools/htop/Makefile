SHELL := /bin/bash
.SHELLFLAGS := -euo pipefail -c

include versions.mk

ARCH ?= amd64
ARCHS := amd64 arm64
DOCKER ?= docker
BUILDX ?= $(DOCKER) buildx
OUT_DIR ?= $(CURDIR)/../../dist
TOOL_OUT_DIR := $(OUT_DIR)/htop
DEPS_PREFIX := $(OUT_DIR)/deps/$(ARCH)
PLATFORM_amd64 := linux/amd64
PLATFORM_arm64 := linux/arm64
ALPINE_DIGEST_amd64 := $(ALPINE_DIGEST_AMD64)
ALPINE_DIGEST_arm64 := $(ALPINE_DIGEST_ARM64)

.PHONY: deps build build-all test verify-static clean info

deps:
	$(MAKE) -C $(CURDIR)/../../deps build ARCH=$(ARCH) OUT_DIR=$(OUT_DIR)

build: $(TOOL_OUT_DIR)/$(ARCH)/htop

$(TOOL_OUT_DIR)/$(ARCH)/htop: Dockerfile versions.mk $(DEPS_PREFIX)/lib/libncursesw.a
	@mkdir -p $(TOOL_OUT_DIR)/$(ARCH)
	$(BUILDX) build \
		--platform $(PLATFORM_$(ARCH)) \
		--build-context deps=$(DEPS_PREFIX) \
		--build-arg ALPINE_VERSION=$(ALPINE_VERSION) \
		--build-arg ALPINE_DIGEST=$(ALPINE_DIGEST_$(ARCH)) \
		--build-arg HTOP_VERSION=$(HTOP_VERSION) \
		--build-arg HTOP_SOURCE_SHA256=$(HTOP_SOURCE_SHA256) \
		--output type=local,dest=$(TOOL_OUT_DIR)/$(ARCH) \
		--target export \
		.
	@echo "Built htop $(HTOP_VERSION) for $(ARCH):"
	@ls -la $(TOOL_OUT_DIR)/$(ARCH)/

$(DEPS_PREFIX)/lib/libncursesw.a:
	$(MAKE) -C $(CURDIR)/../../deps build ARCH=$(ARCH) OUT_DIR=$(OUT_DIR)

build-all:
	$(foreach arch,$(ARCHS),$(MAKE) build ARCH=$(arch);)

test: build
	@echo "==> Testing htop binary for $(ARCH)"
	@test -x $(TOOL_OUT_DIR)/$(ARCH)/htop || (echo "ERROR: htop binary not found" && exit 1)
	@file $(TOOL_OUT_DIR)/$(ARCH)/htop | grep -q "statically linked" || (echo "ERROR: not statically linked" && exit 1)
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/htop:/htop:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST_$(ARCH)) /htop --version 2>&1) && \
		echo "$$OUTPUT" | grep -qi "htop" || (echo "ERROR: htop --version failed: $$OUTPUT" && exit 1)
	@echo "✓ htop --version works"
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/htop:/htop:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST_$(ARCH)) /htop --help 2>&1) && \
		echo "$$OUTPUT" | grep -qi "usage\|htop" || (echo "ERROR: htop --help failed: $$OUTPUT" && exit 1)
	@echo "✓ htop --help works"
	@echo "==> All htop tests passed"

verify-static: build
	@file $(TOOL_OUT_DIR)/$(ARCH)/htop

clean:
	rm -rf $(TOOL_OUT_DIR)

info:
	@echo "Tool: htop $(HTOP_VERSION)"
	@echo "URL: $(HTOP_SOURCE_URL)"
	@echo "SHA256: $(HTOP_SOURCE_SHA256)"
