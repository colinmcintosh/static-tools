# openssl CLI build targets

SHELL := /bin/bash
.SHELLFLAGS := -euo pipefail -c

include versions.mk

ARCH ?= amd64
ARCHS := amd64 arm64

DOCKER ?= docker
BUILDX ?= $(DOCKER) buildx

OUT_DIR ?= $(CURDIR)/../../dist
TOOL_OUT_DIR := $(OUT_DIR)/openssl
DEPS_PREFIX := $(OUT_DIR)/deps/$(ARCH)

PLATFORM_amd64 := linux/amd64
PLATFORM_arm64 := linux/arm64

ALPINE_DIGEST_amd64 := $(ALPINE_DIGEST_AMD64)
ALPINE_DIGEST_arm64 := $(ALPINE_DIGEST_ARM64)

.PHONY: deps
deps:
	$(MAKE) -C $(CURDIR)/../../deps build ARCH=$(ARCH) OUT_DIR=$(OUT_DIR)

.PHONY: build
build: $(TOOL_OUT_DIR)/$(ARCH)/openssl

$(TOOL_OUT_DIR)/$(ARCH)/openssl: Dockerfile versions.mk $(DEPS_PREFIX)/lib/libssl.a
	@mkdir -p $(TOOL_OUT_DIR)/$(ARCH)
	$(BUILDX) build \
		--platform $(PLATFORM_$(ARCH)) \
		--build-context deps=$(DEPS_PREFIX) \
		--build-arg ALPINE_VERSION=$(ALPINE_VERSION) \
		--build-arg ALPINE_DIGEST=$(ALPINE_DIGEST_$(ARCH)) \
		--output type=local,dest=$(TOOL_OUT_DIR)/$(ARCH) \
		--target export \
		.
	@echo "Built openssl $(OPENSSL_VERSION) for $(ARCH):"
	@ls -la $(TOOL_OUT_DIR)/$(ARCH)/

$(DEPS_PREFIX)/lib/libssl.a:
	$(MAKE) -C $(CURDIR)/../../deps build ARCH=$(ARCH) OUT_DIR=$(OUT_DIR)

.PHONY: build-all
build-all:
	$(foreach arch,$(ARCHS),$(MAKE) build ARCH=$(arch);)

.PHONY: test
test: build
	@echo "==> Testing openssl binary for $(ARCH)"
	@test -x $(TOOL_OUT_DIR)/$(ARCH)/openssl || \
		(echo "ERROR: openssl binary not found or not executable" && exit 1)
	@echo "✓ openssl binary exists"
	@file $(TOOL_OUT_DIR)/$(ARCH)/openssl | grep -q "statically linked" || \
		(echo "ERROR: Binary is not statically linked" && exit 1)
	@echo "✓ openssl binary is statically linked"
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/openssl:/openssl:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST_$(ARCH)) /openssl version 2>&1) && \
		echo "$$OUTPUT" | grep -q "$(OPENSSL_VERSION)" || \
		(echo "ERROR: openssl version failed: $$OUTPUT" && exit 1)
	@echo "✓ openssl version works"
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/openssl:/openssl:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST_$(ARCH)) \
		/bin/sh -c 'printf test | /openssl dgst -sha256' 2>&1) && \
		echo "$$OUTPUT" | grep -qi "9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08" || \
		(echo "ERROR: openssl dgst failed: $$OUTPUT" && exit 1)
	@echo "✓ openssl dgst -sha256 works"
	@echo "==> All openssl tests passed"

.PHONY: verify-static
verify-static: build
	@echo "==> Checking openssl binary linking for $(ARCH)"
	@file $(TOOL_OUT_DIR)/$(ARCH)/openssl

.PHONY: clean
clean:
	rm -rf $(TOOL_OUT_DIR)

.PHONY: info
info:
	@echo "Tool: openssl (cryptography CLI)"
	@echo "Source: OpenSSL $(OPENSSL_VERSION)"
	@echo "URL: $(OPENSSL_URL)"
	@echo "SHA256: $(OPENSSL_SHA256)"
