SHELL := /bin/bash
.SHELLFLAGS := -euo pipefail -c

include versions.mk

ARCH ?= amd64
ARCHS := amd64 arm64
DOCKER ?= docker
BUILDX ?= $(DOCKER) buildx
OUT_DIR ?= $(CURDIR)/../../dist
TOOL_OUT_DIR := $(OUT_DIR)/fping
PLATFORM_amd64 := linux/amd64
PLATFORM_arm64 := linux/arm64
ALPINE_DIGEST_amd64 := $(ALPINE_DIGEST_AMD64)
ALPINE_DIGEST_arm64 := $(ALPINE_DIGEST_ARM64)

.PHONY: build build-all test verify-static clean info

build: $(TOOL_OUT_DIR)/$(ARCH)/fping

$(TOOL_OUT_DIR)/$(ARCH)/fping: Dockerfile versions.mk
	@mkdir -p $(TOOL_OUT_DIR)/$(ARCH)
	$(BUILDX) build \
		--platform $(PLATFORM_$(ARCH)) \
		--build-arg ALPINE_VERSION=$(ALPINE_VERSION) \
		--build-arg ALPINE_DIGEST=$(ALPINE_DIGEST_$(ARCH)) \
		--build-arg FPING_VERSION=$(FPING_VERSION) \
		--build-arg FPING_SOURCE_SHA256=$(FPING_SOURCE_SHA256) \
		--output type=local,dest=$(TOOL_OUT_DIR)/$(ARCH) \
		--target export \
		.
	@echo "Built fping $(FPING_VERSION) for $(ARCH):"
	@ls -la $(TOOL_OUT_DIR)/$(ARCH)/

build-all:
	$(foreach arch,$(ARCHS),$(MAKE) build ARCH=$(arch);)

test: build
	@echo "==> Testing fping binary for $(ARCH)"
	@test -x $(TOOL_OUT_DIR)/$(ARCH)/fping || (echo "ERROR: fping binary not found" && exit 1)
	@file $(TOOL_OUT_DIR)/$(ARCH)/fping | grep -q "statically linked" || (echo "ERROR: not statically linked" && exit 1)
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/fping:/fping:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST_$(ARCH)) /fping -v 2>&1) && \
		echo "$$OUTPUT" | grep -qi "fping" || (echo "ERROR: fping -v failed: $$OUTPUT" && exit 1)
	@echo "✓ fping -v works"
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/fping:/fping:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST_$(ARCH)) /fping -h 2>&1) && \
		echo "$$OUTPUT" | grep -qi "usage\|fping" || (echo "ERROR: fping -h failed: $$OUTPUT" && exit 1)
	@echo "✓ fping -h works"
	@echo "==> All fping tests passed"

verify-static: build
	@file $(TOOL_OUT_DIR)/$(ARCH)/fping

clean:
	rm -rf $(TOOL_OUT_DIR)

info:
	@echo "Tool: fping $(FPING_VERSION)"
	@echo "URL: $(FPING_SOURCE_URL)"
	@echo "SHA256: $(FPING_SOURCE_SHA256)"
