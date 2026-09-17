SHELL := /bin/bash
.SHELLFLAGS := -euo pipefail -c

include versions.mk

ARCH ?= amd64
ARCHS := amd64 arm64
DOCKER ?= docker
BUILDX ?= $(DOCKER) buildx
OUT_DIR ?= $(CURDIR)/../../dist
TOOL_OUT_DIR := $(OUT_DIR)/tree
PLATFORM_amd64 := linux/amd64
PLATFORM_arm64 := linux/arm64
ALPINE_DIGEST_amd64 := $(ALPINE_DIGEST_AMD64)
ALPINE_DIGEST_arm64 := $(ALPINE_DIGEST_ARM64)

.PHONY: build build-all test verify-static clean info

build: $(TOOL_OUT_DIR)/$(ARCH)/tree

$(TOOL_OUT_DIR)/$(ARCH)/tree: Dockerfile versions.mk
	@mkdir -p $(TOOL_OUT_DIR)/$(ARCH)
	$(BUILDX) build \
		--platform $(PLATFORM_$(ARCH)) \
		--build-arg BUILDER_IMAGE=$(BUILDER_IMAGE) \
		--build-arg BUILDER_DIGEST=$(BUILDER_DIGEST) \
		--build-arg TREE_VERSION=$(TREE_VERSION) \
		--build-arg TREE_SOURCE_SHA256=$(TREE_SOURCE_SHA256) \
		--output type=local,dest=$(TOOL_OUT_DIR)/$(ARCH) \
		--target export \
		.
	@echo "Built tree $(TREE_VERSION) for $(ARCH):"
	@ls -la $(TOOL_OUT_DIR)/$(ARCH)/

build-all:
	$(foreach arch,$(ARCHS),$(MAKE) build ARCH=$(arch);)

test: build
	@echo "==> Testing tree binary for $(ARCH)"
	@test -x $(TOOL_OUT_DIR)/$(ARCH)/tree || (echo "ERROR: tree binary not found" && exit 1)
	@$(CURDIR)/../../scripts/assert-static-elf.sh $(TOOL_OUT_DIR)/$(ARCH)/tree
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/tree:/tree:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST_$(ARCH)) /tree --version 2>&1) && \
		echo "$$OUTPUT" | grep -qi "tree v$(TREE_VERSION)" || (echo "ERROR: tree --version failed: $$OUTPUT" && exit 1)
	@echo "✓ tree --version works"
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/tree:/tree:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST_$(ARCH)) \
		/bin/sh -c 'mkdir -p /fixture/subdir && touch /fixture/file-a.txt /fixture/subdir/file-b.txt && /tree /fixture' 2>&1) && \
		( echo "$$OUTPUT" | grep -q "file-a.txt" ) && \
		( echo "$$OUTPUT" | grep -q "subdir" ) && \
		( echo "$$OUTPUT" | grep -q "file-b.txt" ) && \
		( echo "$$OUTPUT" | grep -qi "2 directories, 2 files\|directories.*files" ) || \
		(echo "ERROR: tree directory listing failed: $$OUTPUT" && exit 1)
	@echo "✓ tree lists a real directory structure"
	@echo "==> All tree tests passed"

verify-static: build
	@$(CURDIR)/../../scripts/assert-static-elf.sh $(TOOL_OUT_DIR)/$(ARCH)/tree

clean:
	rm -rf $(TOOL_OUT_DIR)

info:
	@echo "Tool: tree (unix-tree $(TREE_VERSION))"
	@echo "URL: $(TREE_SOURCE_URL)"
	@echo "SHA256: $(TREE_SOURCE_SHA256)"
