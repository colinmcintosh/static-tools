SHELL := /bin/bash
.SHELLFLAGS := -euo pipefail -c

include versions.mk

ARCH ?= amd64
ARCHS := amd64 arm64
DOCKER ?= docker
BUILDX ?= $(DOCKER) buildx
OUT_DIR ?= $(CURDIR)/../../dist
TOOL_OUT_DIR := $(OUT_DIR)/whois
PLATFORM_amd64 := linux/amd64
PLATFORM_arm64 := linux/arm64
ALPINE_DIGEST_amd64 := $(ALPINE_DIGEST_AMD64)
ALPINE_DIGEST_arm64 := $(ALPINE_DIGEST_ARM64)

.PHONY: build build-all test verify-static clean info

build: $(TOOL_OUT_DIR)/$(ARCH)/whois

$(TOOL_OUT_DIR)/$(ARCH)/whois: Dockerfile versions.mk
	@mkdir -p $(TOOL_OUT_DIR)/$(ARCH)
	$(BUILDX) build \
		--platform $(PLATFORM_$(ARCH)) \
		--build-arg BUILDER_IMAGE=$(BUILDER_IMAGE) \
		--build-arg BUILDER_DIGEST=$(BUILDER_DIGEST) \
		--build-arg WHOIS_VERSION=$(WHOIS_VERSION) \
		--build-arg WHOIS_SOURCE_SHA256=$(WHOIS_SOURCE_SHA256) \
		--output type=local,dest=$(TOOL_OUT_DIR)/$(ARCH) \
		--target export \
		.
	@echo "Built whois $(WHOIS_VERSION) for $(ARCH):"
	@ls -la $(TOOL_OUT_DIR)/$(ARCH)/

build-all:
	$(foreach arch,$(ARCHS),$(MAKE) build ARCH=$(arch);)

test: build
	@echo "==> Testing whois binary for $(ARCH)"
	@test -x $(TOOL_OUT_DIR)/$(ARCH)/whois || (echo "ERROR: whois binary not found" && exit 1)
	@$(CURDIR)/../../scripts/assert-static-elf.sh $(TOOL_OUT_DIR)/$(ARCH)/whois
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/whois:/whois:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST_$(ARCH)) /whois --version 2>&1) && \
		echo "$$OUTPUT" | grep -q "$(WHOIS_VERSION)" || (echo "ERROR: whois --version failed: $$OUTPUT" && exit 1)
	@echo "✓ whois --version works"
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/whois:/whois:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST_$(ARCH)) /whois --help 2>&1) && \
		echo "$$OUTPUT" | grep -qi "usage" || (echo "ERROR: whois --help failed: $$OUTPUT" && exit 1)
	@echo "✓ whois --help works"
	@echo "==> All whois tests passed"

verify-static: build
	@$(CURDIR)/../../scripts/assert-static-elf.sh $(TOOL_OUT_DIR)/$(ARCH)/whois

clean:
	rm -rf $(TOOL_OUT_DIR)

info:
	@echo "Tool: whois $(WHOIS_VERSION)"
	@echo "URL: $(WHOIS_SOURCE_URL)"
	@echo "SHA256: $(WHOIS_SOURCE_SHA256)"
