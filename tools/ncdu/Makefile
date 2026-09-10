SHELL := /bin/bash
.SHELLFLAGS := -euo pipefail -c

include versions.mk

ARCH ?= amd64
ARCHS := amd64 arm64
DOCKER ?= docker
BUILDX ?= $(DOCKER) buildx
OUT_DIR ?= $(CURDIR)/../../dist
TOOL_OUT_DIR := $(OUT_DIR)/ncdu
DEPS_PREFIX := $(OUT_DIR)/deps/$(ARCH)
PLATFORM_amd64 := linux/amd64
PLATFORM_arm64 := linux/arm64
ALPINE_DIGEST_amd64 := $(ALPINE_DIGEST_AMD64)
ALPINE_DIGEST_arm64 := $(ALPINE_DIGEST_ARM64)

.PHONY: deps build build-all test verify-static clean info

deps:
	$(MAKE) -C $(CURDIR)/../../deps build ARCH=$(ARCH) OUT_DIR=$(OUT_DIR)

build: $(TOOL_OUT_DIR)/$(ARCH)/ncdu

$(TOOL_OUT_DIR)/$(ARCH)/ncdu: Dockerfile versions.mk $(DEPS_PREFIX)/lib/libncursesw.a
	@mkdir -p $(TOOL_OUT_DIR)/$(ARCH)
	$(BUILDX) build \
		--platform $(PLATFORM_$(ARCH)) \
		--build-context deps=$(DEPS_PREFIX) \
		--build-arg ALPINE_VERSION=$(ALPINE_VERSION) \
		--build-arg ALPINE_DIGEST=$(ALPINE_DIGEST_$(ARCH)) \
		--build-arg NCDU_VERSION=$(NCDU_VERSION) \
		--build-arg NCDU_SOURCE_SHA256=$(NCDU_SOURCE_SHA256) \
		--output type=local,dest=$(TOOL_OUT_DIR)/$(ARCH) \
		--target export \
		.
	@echo "Built ncdu $(NCDU_VERSION) for $(ARCH):"
	@ls -la $(TOOL_OUT_DIR)/$(ARCH)/

$(DEPS_PREFIX)/lib/libncursesw.a:
	$(MAKE) -C $(CURDIR)/../../deps build ARCH=$(ARCH) OUT_DIR=$(OUT_DIR)

build-all:
	$(foreach arch,$(ARCHS),$(MAKE) build ARCH=$(arch);)

test: build
	@echo "==> Testing ncdu binary for $(ARCH)"
	@test -x $(TOOL_OUT_DIR)/$(ARCH)/ncdu || (echo "ERROR: ncdu binary not found" && exit 1)
	@$(CURDIR)/../../scripts/assert-static-elf.sh $(TOOL_OUT_DIR)/$(ARCH)/ncdu
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/ncdu:/ncdu:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST_$(ARCH)) /ncdu -v 2>&1) && \
		echo "$$OUTPUT" | grep -qi "ncdu" || (echo "ERROR: ncdu -v failed: $$OUTPUT" && exit 1)
	@echo "✓ ncdu -v works"
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/ncdu:/ncdu:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST_$(ARCH)) /ncdu -h 2>&1) && \
		echo "$$OUTPUT" | grep -qi "usage\|ncdu" || (echo "ERROR: ncdu -h failed: $$OUTPUT" && exit 1)
	@echo "✓ ncdu -h works"
	@echo "==> All ncdu tests passed"

verify-static: build
	@$(CURDIR)/../../scripts/assert-static-elf.sh $(TOOL_OUT_DIR)/$(ARCH)/ncdu

clean:
	rm -rf $(TOOL_OUT_DIR)

info:
	@echo "Tool: ncdu $(NCDU_VERSION)"
	@echo "URL: $(NCDU_SOURCE_URL)"
	@echo "SHA256: $(NCDU_SOURCE_SHA256)"
