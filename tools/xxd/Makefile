SHELL := /bin/bash
.SHELLFLAGS := -euo pipefail -c

include versions.mk

ARCH ?= amd64
ARCHS := amd64 arm64
DOCKER ?= docker
BUILDX ?= $(DOCKER) buildx
OUT_DIR ?= $(CURDIR)/../../dist
TOOL_OUT_DIR := $(OUT_DIR)/xxd
DEPS_PREFIX := $(OUT_DIR)/deps/$(ARCH)
PLATFORM_amd64 := linux/amd64
PLATFORM_arm64 := linux/arm64
ALPINE_DIGEST_amd64 := $(ALPINE_DIGEST_AMD64)
ALPINE_DIGEST_arm64 := $(ALPINE_DIGEST_ARM64)

.PHONY: deps build build-all test verify-static clean info

deps:
	$(MAKE) -C $(CURDIR)/../../deps build ARCH=$(ARCH) OUT_DIR=$(OUT_DIR)

build: $(TOOL_OUT_DIR)/$(ARCH)/xxd

$(TOOL_OUT_DIR)/$(ARCH)/xxd: Dockerfile versions.mk $(DEPS_PREFIX)/lib/libssl.a
	@mkdir -p $(TOOL_OUT_DIR)/$(ARCH)
	$(BUILDX) build \
		--platform $(PLATFORM_$(ARCH)) \
		--build-context deps=$(DEPS_PREFIX) \
		--build-arg ALPINE_VERSION=$(ALPINE_VERSION) \
		--build-arg ALPINE_DIGEST=$(ALPINE_DIGEST_$(ARCH)) \
		--build-arg XXD_VERSION=$(XXD_VERSION) \
		--build-arg XXD_SOURCE_SHA256=$(XXD_SOURCE_SHA256) \
		--output type=local,dest=$(TOOL_OUT_DIR)/$(ARCH) \
		--target export \
		.
	@echo "Built xxd $(XXD_VERSION) for $(ARCH):"
	@ls -la $(TOOL_OUT_DIR)/$(ARCH)/

$(DEPS_PREFIX)/lib/libssl.a:
	$(MAKE) -C $(CURDIR)/../../deps build ARCH=$(ARCH) OUT_DIR=$(OUT_DIR)

build-all:
	$(foreach arch,$(ARCHS),$(MAKE) build ARCH=$(arch);)

test: build
	@echo "==> Testing xxd binary for $(ARCH)"
	@test -x $(TOOL_OUT_DIR)/$(ARCH)/xxd || (echo "ERROR: xxd binary not found" && exit 1)
	@file $(TOOL_OUT_DIR)/$(ARCH)/xxd | grep -q "statically linked" || (echo "ERROR: not statically linked" && exit 1)
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/xxd:/xxd:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST_$(ARCH)) \
		/bin/sh -c 'printf ABC | /xxd' 2>&1) && \
		echo "$$OUTPUT" | grep -qi "4142" || (echo "ERROR: xxd encode failed: $$OUTPUT" && exit 1)
	@echo "✓ xxd encodes hex"
	@echo "==> All xxd tests passed"

verify-static: build
	@file $(TOOL_OUT_DIR)/$(ARCH)/xxd

clean:
	rm -rf $(TOOL_OUT_DIR)

info:
	@echo "Tool: xxd (tinyxxd $(XXD_VERSION))"
	@echo "URL: $(XXD_SOURCE_URL)"
	@echo "SHA256: $(XXD_SOURCE_SHA256)"
