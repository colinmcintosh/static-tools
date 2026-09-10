SHELL := /bin/bash
.SHELLFLAGS := -euo pipefail -c

include versions.mk

ARCH ?= amd64
ARCHS := amd64 arm64
DOCKER ?= docker
BUILDX ?= $(DOCKER) buildx
OUT_DIR ?= $(CURDIR)/../../dist
TOOL_OUT_DIR := $(OUT_DIR)/jq
PLATFORM_amd64 := linux/amd64
PLATFORM_arm64 := linux/arm64
ALPINE_DIGEST_amd64 := $(ALPINE_DIGEST_AMD64)
ALPINE_DIGEST_arm64 := $(ALPINE_DIGEST_ARM64)

.PHONY: build build-all test verify-static clean info

build: $(TOOL_OUT_DIR)/$(ARCH)/jq

$(TOOL_OUT_DIR)/$(ARCH)/jq: Dockerfile versions.mk
	@mkdir -p $(TOOL_OUT_DIR)/$(ARCH)
	$(BUILDX) build \
		--platform $(PLATFORM_$(ARCH)) \
		--build-arg ALPINE_VERSION=$(ALPINE_VERSION) \
		--build-arg ALPINE_DIGEST=$(ALPINE_DIGEST_$(ARCH)) \
		--build-arg JQ_VERSION=$(JQ_VERSION) \
		--build-arg JQ_SOURCE_SHA256=$(JQ_SOURCE_SHA256) \
		--output type=local,dest=$(TOOL_OUT_DIR)/$(ARCH) \
		--target export \
		.
	@echo "Built jq $(JQ_VERSION) for $(ARCH):"
	@ls -la $(TOOL_OUT_DIR)/$(ARCH)/

build-all:
	$(foreach arch,$(ARCHS),$(MAKE) build ARCH=$(arch);)

test: build
	@echo "==> Testing jq binary for $(ARCH)"
	@test -x $(TOOL_OUT_DIR)/$(ARCH)/jq || (echo "ERROR: jq binary not found" && exit 1)
	@$(CURDIR)/../../scripts/assert-static-elf.sh $(TOOL_OUT_DIR)/$(ARCH)/jq
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/jq:/jq:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST_$(ARCH)) /jq --version 2>&1) && \
		echo "$$OUTPUT" | grep -qi "jq" || (echo "ERROR: jq --version failed: $$OUTPUT" && exit 1)
	@echo "✓ jq --version works"
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/jq:/jq:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST_$(ARCH)) \
		/bin/sh -c 'printf "{\"a\":1}" | /jq -r .a' 2>&1) && \
		echo "$$OUTPUT" | grep -qx "1" || (echo "ERROR: jq filter failed: $$OUTPUT" && exit 1)
	@echo "✓ jq filter works"
	@echo "==> All jq tests passed"

verify-static: build
	@$(CURDIR)/../../scripts/assert-static-elf.sh $(TOOL_OUT_DIR)/$(ARCH)/jq

clean:
	rm -rf $(TOOL_OUT_DIR)

info:
	@echo "Tool: jq $(JQ_VERSION)"
	@echo "URL: $(JQ_SOURCE_URL)"
	@echo "SHA256: $(JQ_SOURCE_SHA256)"
