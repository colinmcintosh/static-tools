SHELL := /bin/bash
.SHELLFLAGS := -euo pipefail -c

include versions.mk

ARCH ?= amd64
ARCHS := amd64 arm64
DOCKER ?= docker
BUILDX ?= $(DOCKER) buildx
OUT_DIR ?= $(CURDIR)/../../dist
TOOL_OUT_DIR := $(OUT_DIR)/file
DEPS_PREFIX := $(OUT_DIR)/deps/$(ARCH)
PLATFORM_amd64 := linux/amd64
PLATFORM_arm64 := linux/arm64
ALPINE_DIGEST_amd64 := $(ALPINE_DIGEST_AMD64)
ALPINE_DIGEST_arm64 := $(ALPINE_DIGEST_ARM64)

.PHONY: deps build build-all test verify-static clean info

deps:
	$(MAKE) -C $(CURDIR)/../../deps build ARCH=$(ARCH) OUT_DIR=$(OUT_DIR)

build: $(TOOL_OUT_DIR)/$(ARCH)/file $(TOOL_OUT_DIR)/$(ARCH)/magic.mgc

$(TOOL_OUT_DIR)/$(ARCH)/file $(TOOL_OUT_DIR)/$(ARCH)/magic.mgc: Dockerfile versions.mk $(DEPS_PREFIX)/lib/libz.a
	@mkdir -p $(TOOL_OUT_DIR)/$(ARCH)
	$(BUILDX) build \
		--platform $(PLATFORM_$(ARCH)) \
		--build-context deps=$(DEPS_PREFIX) \
		--build-arg ALPINE_VERSION=$(ALPINE_VERSION) \
		--build-arg ALPINE_DIGEST=$(ALPINE_DIGEST_$(ARCH)) \
		--build-arg FILE_VERSION=$(FILE_VERSION) \
		--build-arg FILE_SOURCE_SHA256=$(FILE_SOURCE_SHA256) \
		--output type=local,dest=$(TOOL_OUT_DIR)/$(ARCH) \
		--target export \
		.
	@echo "Built file $(FILE_VERSION) for $(ARCH):"
	@ls -la $(TOOL_OUT_DIR)/$(ARCH)/

$(DEPS_PREFIX)/lib/libz.a:
	$(MAKE) -C $(CURDIR)/../../deps build ARCH=$(ARCH) OUT_DIR=$(OUT_DIR)

build-all:
	$(foreach arch,$(ARCHS),$(MAKE) build ARCH=$(arch);)

test: build
	@echo "==> Testing file binary for $(ARCH)"
	@test -x $(TOOL_OUT_DIR)/$(ARCH)/file || (echo "ERROR: file binary not found" && exit 1)
	@test -f $(TOOL_OUT_DIR)/$(ARCH)/magic.mgc || (echo "ERROR: magic.mgc not found" && exit 1)
	@file $(TOOL_OUT_DIR)/$(ARCH)/file | grep -q "statically linked" || (echo "ERROR: not statically linked" && exit 1)
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/file:/file:ro \
		-v $(TOOL_OUT_DIR)/$(ARCH)/magic.mgc:/magic.mgc:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST_$(ARCH)) /file --version 2>&1) && \
		echo "$$OUTPUT" | grep -qi "file" || (echo "ERROR: file --version failed: $$OUTPUT" && exit 1)
	@echo "✓ file --version works"
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/file:/file:ro \
		-v $(TOOL_OUT_DIR)/$(ARCH)/magic.mgc:/magic.mgc:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST_$(ARCH)) /file -m /magic.mgc /file 2>&1) && \
		echo "$$OUTPUT" | grep -qi "elf\|executable" || (echo "ERROR: file identify failed: $$OUTPUT" && exit 1)
	@echo "✓ file can identify an ELF binary"
	@echo "==> All file tests passed"

verify-static: build
	@file $(TOOL_OUT_DIR)/$(ARCH)/file

clean:
	rm -rf $(TOOL_OUT_DIR)

info:
	@echo "Tool: file $(FILE_VERSION)"
	@echo "URL: $(FILE_SOURCE_URL)"
	@echo "SHA256: $(FILE_SOURCE_SHA256)"
