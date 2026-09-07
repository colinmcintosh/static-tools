# Shared static prefix built from upstream tarballs

SHELL := /bin/bash
.SHELLFLAGS := -euo pipefail -c

include versions.mk

ARCH ?= amd64
ARCHS := amd64 arm64

DOCKER ?= docker
BUILDX ?= $(DOCKER) buildx

OUT_DIR ?= $(CURDIR)/../dist
DEPS_OUT_DIR := $(OUT_DIR)/deps

PLATFORM_amd64 := linux/amd64
PLATFORM_arm64 := linux/arm64

ALPINE_DIGEST_amd64 := $(ALPINE_DIGEST_AMD64)
ALPINE_DIGEST_arm64 := $(ALPINE_DIGEST_ARM64)

.PHONY: build
build: $(DEPS_OUT_DIR)/$(ARCH)/lib/libssl.a

$(DEPS_OUT_DIR)/$(ARCH)/lib/libssl.a: Dockerfile versions.mk
	@mkdir -p $(DEPS_OUT_DIR)/$(ARCH)
	$(BUILDX) build \
		--platform $(PLATFORM_$(ARCH)) \
		--build-arg ALPINE_VERSION=$(ALPINE_VERSION) \
		--build-arg ALPINE_DIGEST=$(ALPINE_DIGEST_$(ARCH)) \
		--build-arg PREFIX=$(PREFIX) \
		--build-arg PERL_VERSION=$(PERL_VERSION) \
		--build-arg PERL_URL=$(PERL_URL) \
		--build-arg PERL_SHA256=$(PERL_SHA256) \
		--build-arg PKG_CONFIG_VERSION=$(PKG_CONFIG_VERSION) \
		--build-arg PKG_CONFIG_URL=$(PKG_CONFIG_URL) \
		--build-arg PKG_CONFIG_SHA256=$(PKG_CONFIG_SHA256) \
		--build-arg ZLIB_VERSION=$(ZLIB_VERSION) \
		--build-arg ZLIB_URL=$(ZLIB_URL) \
		--build-arg ZLIB_SHA256=$(ZLIB_SHA256) \
		--build-arg OPENSSL_VERSION=$(OPENSSL_VERSION) \
		--build-arg OPENSSL_URL=$(OPENSSL_URL) \
		--build-arg OPENSSL_SHA256=$(OPENSSL_SHA256) \
		--build-arg NGHTTP2_VERSION=$(NGHTTP2_VERSION) \
		--build-arg NGHTTP2_URL=$(NGHTTP2_URL) \
		--build-arg NGHTTP2_SHA256=$(NGHTTP2_SHA256) \
		--output type=local,dest=$(DEPS_OUT_DIR)/$(ARCH) \
		--target export \
		.
	@echo "Built static prefix for $(ARCH):"
	@ls -la $(DEPS_OUT_DIR)/$(ARCH)/lib

.PHONY: build-all
build-all:
	$(foreach arch,$(ARCHS),$(MAKE) build ARCH=$(arch);)

.PHONY: clean
clean:
	rm -rf $(DEPS_OUT_DIR)

.PHONY: info
info:
	@echo "Static prefix: $(PREFIX)"
	@echo "OpenSSL $(OPENSSL_VERSION)"
	@echo "zlib $(ZLIB_VERSION)"
	@echo "nghttp2 $(NGHTTP2_VERSION)"
