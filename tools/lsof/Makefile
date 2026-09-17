SHELL := /bin/bash
.SHELLFLAGS := -euo pipefail -c

include versions.mk

ARCH ?= amd64
ARCHS := amd64 arm64
DOCKER ?= docker
BUILDX ?= $(DOCKER) buildx
OUT_DIR ?= $(CURDIR)/../../dist
TOOL_OUT_DIR := $(OUT_DIR)/lsof
PLATFORM_amd64 := linux/amd64
PLATFORM_arm64 := linux/arm64
ALPINE_DIGEST_amd64 := $(ALPINE_DIGEST_AMD64)
ALPINE_DIGEST_arm64 := $(ALPINE_DIGEST_ARM64)

.PHONY: build build-all test verify-static clean info

build: $(TOOL_OUT_DIR)/$(ARCH)/lsof

$(TOOL_OUT_DIR)/$(ARCH)/lsof: Dockerfile versions.mk
	@mkdir -p $(TOOL_OUT_DIR)/$(ARCH)
	$(BUILDX) build \
		--platform $(PLATFORM_$(ARCH)) \
		--build-arg BUILDER_IMAGE=$(BUILDER_IMAGE) \
		--build-arg BUILDER_DIGEST=$(BUILDER_DIGEST) \
		--build-arg LSOF_VERSION=$(LSOF_VERSION) \
		--build-arg LSOF_SOURCE_SHA256=$(LSOF_SOURCE_SHA256) \
		--output type=local,dest=$(TOOL_OUT_DIR)/$(ARCH) \
		--target export \
		.
	@echo "Built lsof $(LSOF_VERSION) for $(ARCH):"
	@ls -la $(TOOL_OUT_DIR)/$(ARCH)/

build-all:
	$(foreach arch,$(ARCHS),$(MAKE) build ARCH=$(arch);)

test: build
	@echo "==> Testing lsof binary for $(ARCH)"
	@test -x $(TOOL_OUT_DIR)/$(ARCH)/lsof || (echo "ERROR: lsof binary not found" && exit 1)
	@echo "✓ lsof binary exists"
	@$(CURDIR)/../../scripts/assert-static-elf.sh $(TOOL_OUT_DIR)/$(ARCH)/lsof
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/lsof:/lsof:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST_$(ARCH)) /lsof -v 2>&1) && \
		echo "$$OUTPUT" | grep -qi "lsof version information" || \
		(echo "ERROR: lsof -v failed: $$OUTPUT" && exit 1)
	@echo "✓ lsof -v works"
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/lsof:/lsof:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST_$(ARCH)) /lsof -p 1 2>&1) && \
		echo "$$OUTPUT" | grep -q "^COMMAND" || \
		(echo "ERROR: lsof -p 1 failed: $$OUTPUT" && exit 1) && \
		echo "$$OUTPUT" | grep -qi "^lsof" || \
		(echo "ERROR: lsof -p 1 did not list its own process: $$OUTPUT" && exit 1)
	@echo "✓ lsof -p 1 works (self-inspection via /proc, zero libraries in the container)"
	@echo "==> All lsof tests passed"

verify-static: build
	@$(CURDIR)/../../scripts/assert-static-elf.sh $(TOOL_OUT_DIR)/$(ARCH)/lsof

clean:
	rm -rf $(TOOL_OUT_DIR)

info:
	@echo "Tool: lsof $(LSOF_VERSION)"
	@echo "URL: $(LSOF_SOURCE_URL)"
	@echo "SHA256: $(LSOF_SOURCE_SHA256)"
