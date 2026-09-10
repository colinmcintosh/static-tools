SHELL := /bin/bash
.SHELLFLAGS := -euo pipefail -c

include versions.mk

ARCH ?= amd64
ARCHS := amd64 arm64
DOCKER ?= docker
BUILDX ?= $(DOCKER) buildx
OUT_DIR ?= $(CURDIR)/../../dist
TOOL_OUT_DIR := $(OUT_DIR)/strace
PLATFORM_amd64 := linux/amd64
PLATFORM_arm64 := linux/arm64
ALPINE_DIGEST_amd64 := $(ALPINE_DIGEST_AMD64)
ALPINE_DIGEST_arm64 := $(ALPINE_DIGEST_ARM64)

.PHONY: build build-all test verify-static clean info

build: $(TOOL_OUT_DIR)/$(ARCH)/strace

$(TOOL_OUT_DIR)/$(ARCH)/strace: Dockerfile versions.mk
	@mkdir -p $(TOOL_OUT_DIR)/$(ARCH)
	$(BUILDX) build \
		--platform $(PLATFORM_$(ARCH)) \
		--build-arg ALPINE_VERSION=$(ALPINE_VERSION) \
		--build-arg ALPINE_DIGEST=$(ALPINE_DIGEST_$(ARCH)) \
		--build-arg STRACE_VERSION=$(STRACE_VERSION) \
		--build-arg STRACE_SOURCE_SHA256=$(STRACE_SOURCE_SHA256) \
		--output type=local,dest=$(TOOL_OUT_DIR)/$(ARCH) \
		--target export \
		.
	@echo "Built strace $(STRACE_VERSION) for $(ARCH):"
	@ls -la $(TOOL_OUT_DIR)/$(ARCH)/

build-all:
	$(foreach arch,$(ARCHS),$(MAKE) build ARCH=$(arch);)

test: build
	@echo "==> Testing strace binary for $(ARCH)"
	@test -x $(TOOL_OUT_DIR)/$(ARCH)/strace || (echo "ERROR: strace binary not found" && exit 1)
	@$(CURDIR)/../../scripts/assert-static-elf.sh $(TOOL_OUT_DIR)/$(ARCH)/strace
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/strace:/strace:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST_$(ARCH)) /strace -V 2>&1) && \
		echo "$$OUTPUT" | grep -qi "strace" || (echo "ERROR: strace -V failed: $$OUTPUT" && exit 1)
	@echo "✓ strace -V works"
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/strace:/strace:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST_$(ARCH)) /strace -e trace=none /bin/true 2>&1) && \
		echo "✓ strace /bin/true works" || (echo "ERROR: strace /bin/true failed: $$OUTPUT" && exit 1)
	@echo "==> All strace tests passed"

verify-static: build
	@$(CURDIR)/../../scripts/assert-static-elf.sh $(TOOL_OUT_DIR)/$(ARCH)/strace

clean:
	rm -rf $(TOOL_OUT_DIR)

info:
	@echo "Tool: strace $(STRACE_VERSION)"
	@echo "URL: $(STRACE_SOURCE_URL)"
	@echo "SHA256: $(STRACE_SOURCE_SHA256)"
