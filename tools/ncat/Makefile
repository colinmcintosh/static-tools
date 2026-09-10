# ncat build targets

SHELL := /bin/bash
.SHELLFLAGS := -euo pipefail -c

include versions.mk

ARCH ?= amd64
ARCHS := amd64 arm64

DOCKER ?= docker
BUILDX ?= $(DOCKER) buildx

OUT_DIR ?= $(CURDIR)/../../dist
TOOL_OUT_DIR := $(OUT_DIR)/ncat
DEPS_PREFIX := $(OUT_DIR)/deps/$(ARCH)

PLATFORM_amd64 := linux/amd64
PLATFORM_arm64 := linux/arm64

ALPINE_DIGEST_amd64 := $(ALPINE_DIGEST_AMD64)
ALPINE_DIGEST_arm64 := $(ALPINE_DIGEST_ARM64)

.PHONY: deps
deps:
	$(MAKE) -C $(CURDIR)/../../deps build ARCH=$(ARCH) OUT_DIR=$(OUT_DIR)

.PHONY: build
build: $(TOOL_OUT_DIR)/$(ARCH)/ncat

$(TOOL_OUT_DIR)/$(ARCH)/ncat: Dockerfile versions.mk $(DEPS_PREFIX)/lib/libssl.a
	@mkdir -p $(TOOL_OUT_DIR)/$(ARCH)
	$(BUILDX) build \
		--platform $(PLATFORM_$(ARCH)) \
		--build-context deps=$(DEPS_PREFIX) \
		--build-arg ALPINE_VERSION=$(ALPINE_VERSION) \
		--build-arg ALPINE_DIGEST=$(ALPINE_DIGEST_$(ARCH)) \
		--build-arg NMAP_VERSION=$(NMAP_VERSION) \
		--build-arg NMAP_SOURCE_SHA256=$(NMAP_SOURCE_SHA256) \
		--output type=local,dest=$(TOOL_OUT_DIR)/$(ARCH) \
		--target export \
		.
	@echo "Built ncat $(NMAP_VERSION) for $(ARCH):"
	@ls -la $(TOOL_OUT_DIR)/$(ARCH)/

$(DEPS_PREFIX)/lib/libssl.a:
	$(MAKE) -C $(CURDIR)/../../deps build ARCH=$(ARCH) OUT_DIR=$(OUT_DIR)

.PHONY: build-all
build-all:
	$(foreach arch,$(ARCHS),$(MAKE) build ARCH=$(arch);)

.PHONY: test
test: build
	@echo "==> Testing ncat binary for $(ARCH)"
	@test -x $(TOOL_OUT_DIR)/$(ARCH)/ncat || \
		(echo "ERROR: ncat binary not found or not executable" && exit 1)
	@echo "✓ ncat binary exists"
	@$(CURDIR)/../../scripts/assert-static-elf.sh $(TOOL_OUT_DIR)/$(ARCH)/ncat
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/ncat:/ncat:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST_$(ARCH)) /ncat --version 2>&1) && \
		echo "$$OUTPUT" | grep -qi "ncat" || \
		(echo "ERROR: ncat --version failed: $$OUTPUT" && exit 1)
	@echo "✓ ncat --version works"
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/ncat:/ncat:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST_$(ARCH)) /ncat --help 2>&1); \
		echo "$$OUTPUT" | grep -qi "usage\|ncat" || \
		(echo "ERROR: ncat --help failed: $$OUTPUT" && exit 1); \
		echo "$$OUTPUT" | grep -q -- "--ssl" || \
		(echo "ERROR: ncat --help missing --ssl: $$OUTPUT" && exit 1)
	@echo "✓ ncat --help reports OpenSSL"
	@$(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/ncat:/ncat:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST_$(ARCH)) \
		/bin/sh -c ' /ncat -l 127.0.0.1 18765 >/tmp/ncat-out & \
			sleep 1; \
			printf ping | /ncat --send-only 127.0.0.1 18765; \
			sleep 1; \
			grep -q ping /tmp/ncat-out ' || \
		(echo "ERROR: ncat loopback test failed" && exit 1)
	@echo "✓ ncat loopback connect works"
	@echo "==> All ncat tests passed"

.PHONY: verify-static
verify-static: build
	@echo "==> Checking ncat binary linking for $(ARCH)"
	@$(CURDIR)/../../scripts/assert-static-elf.sh $(TOOL_OUT_DIR)/$(ARCH)/ncat

.PHONY: clean
clean:
	rm -rf $(TOOL_OUT_DIR)

.PHONY: info
info:
	@echo "Tool: ncat (nmap netcat)"
	@echo "Source: nmap $(NMAP_VERSION)"
	@echo "URL: $(NMAP_SOURCE_URL)"
	@echo "SHA256: $(NMAP_SOURCE_SHA256)"
