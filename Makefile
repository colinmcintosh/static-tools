# static-tools - Statically compiled binaries with SLSA provenance
# Main entry point for building binaries

SHELL := /bin/bash
.SHELLFLAGS := -euo pipefail -c

# Detect host architecture
UNAME_M := $(shell uname -m)
ifeq ($(UNAME_M),x86_64)
    HOST_ARCH := amd64
else ifeq ($(UNAME_M),aarch64)
    HOST_ARCH := arm64
else ifeq ($(UNAME_M),arm64)
    HOST_ARCH := arm64
else
    $(error Unsupported architecture: $(UNAME_M))
endif

# Architecture for build-% / test-% (CI sets ARCH=; local defaults to host)
ARCH ?= $(HOST_ARCH)

# Docker configuration
DOCKER ?= docker
BUILDX ?= $(DOCKER) buildx

# Output directory
OUT_DIR := $(CURDIR)/dist

# All tools
TOOLS := mtr drill dig curl wget iperf3 tcpdump ncat openssl rsync socat jq fping strace ncdu file xxd htop

# Versioning Format: YYYY.MM.MINOR
# YYYY = year, MM = zero-padded month, MINOR = release number within month
YEAR := $(shell date +%Y)
MONTH := $(shell date +%m)
# Auto-increment MINOR based on last tag for this year.month
LAST_MINOR := $(shell git tag -l "v$(YEAR).$(MONTH).*" 2>/dev/null | sed 's/v[0-9]*\.[0-9]*\.\([0-9]*\).*/\1/' | sort -n | tail -1)
MINOR ?= $(if $(LAST_MINOR),$(shell echo $$(($(LAST_MINOR) + 1))),0)
VERSION ?= v$(YEAR).$(MONTH).$(MINOR)

# Version
.PHONY: version
version: ## Print the current version
	@echo "$(VERSION)"

.PHONY: tag-release
tag-release: ## Tag the current commit with the release version
	@echo "Tagging release $(VERSION)..."
	git tag -a "$(VERSION)" -m "Release $(VERSION)"
	@echo "Created tag $(VERSION)"
	@echo "Run 'git push origin $(VERSION)' to push the tag and trigger release"

# Default target
.PHONY: all
all: build

# Shared static library prefix (openssl, zlib, nghttp2, ...)
.PHONY: deps
deps:
	@echo "==> Building static prefix for $(HOST_ARCH)"
	$(MAKE) -C deps build ARCH=$(HOST_ARCH) OUT_DIR=$(OUT_DIR)

.PHONY: deps-all
deps-all:
	$(MAKE) -C deps build-all OUT_DIR=$(OUT_DIR)

# Build all tools for host architecture (local development)
.PHONY: build
build: $(addprefix build-,$(TOOLS))

# Build specific tool for host architecture
.PHONY: build-%
build-%:
	@echo "==> Building $* for $(ARCH)"
	$(MAKE) -C tools/$* build ARCH=$(ARCH) OUT_DIR=$(OUT_DIR)

# Build all tools for all architectures (CI)
.PHONY: build-all
build-all: $(addprefix build-all-,$(TOOLS))

.PHONY: build-all-%
build-all-%:
	@echo "==> Building $* for all architectures"
	$(MAKE) -C tools/$* build-all OUT_DIR=$(OUT_DIR)

# Test all tools
.PHONY: test
test: $(addprefix test-,$(TOOLS))

.PHONY: test-%
test-%:
	@echo "==> Testing $*"
	$(MAKE) -C tools/$* test ARCH=$(ARCH)

# Pinned hadolint v2.12.0 (SHA256 from GitHub release checksum files)
HADOLINT_VERSION := 2.12.0
HADOLINT_SHA256_amd64 := 56de6d5e5ec427e17b74fa48d51271c7fc0d61244bf5c90e828aab8362d55010
HADOLINT_SHA256_arm64 := 5798551bf19f33951881f15eb238f90aef023f11e7ec7e9f4c37961cb87c5df6

# Lint Dockerfiles and scripts
.PHONY: lint
lint:
	@echo "==> Linting Dockerfiles"
	@HADOLINT_SHA256="$(HADOLINT_SHA256_$(HOST_ARCH))"; \
	if [ "$(HOST_ARCH)" = "amd64" ]; then \
		HADOLINT_ASSET="hadolint-Linux-x86_64"; \
	else \
		HADOLINT_ASSET="hadolint-Linux-arm64"; \
	fi; \
	HADOLINT=$$(command -v hadolint 2>/dev/null || echo ""); \
	if [ -n "$$HADOLINT" ] && [ -x "$$HADOLINT" ] && echo "$$HADOLINT_SHA256  $$HADOLINT" | sha256sum -c - >/dev/null 2>&1; then \
		true; \
	else \
		echo "Installing hadolint v$(HADOLINT_VERSION)..."; \
		wget -qO /tmp/hadolint "https://github.com/hadolint/hadolint/releases/download/v$(HADOLINT_VERSION)/$$HADOLINT_ASSET"; \
		echo "$$HADOLINT_SHA256  /tmp/hadolint" | sha256sum -c -; \
		chmod +x /tmp/hadolint; \
		HADOLINT=/tmp/hadolint; \
	fi; \
	$$HADOLINT --config .hadolint.yaml deps/Dockerfile || exit 1; \
	for tool in $(TOOLS); do \
		$$HADOLINT --config .hadolint.yaml tools/$$tool/Dockerfile || exit 1; \
	done
	@echo "✓ Lint passed"

# Clean build artifacts
.PHONY: clean
clean:
	rm -rf $(OUT_DIR)
	$(MAKE) -C deps clean OUT_DIR=$(OUT_DIR);
	$(foreach tool,$(TOOLS),$(MAKE) -C tools/$(tool) clean;)

# List available tools
.PHONY: list
list:
	@echo "Available tools: $(TOOLS)"
	@echo "Host architecture: $(HOST_ARCH)"

# Help
.PHONY: help
help:
	@echo "static-tools - Statically compiled binaries with SLSA provenance"
	@echo ""
	@echo "Usage:"
	@echo "  make deps           Build shared static library prefix for $(HOST_ARCH)"
	@echo "  make build          Build all tools for host architecture ($(HOST_ARCH))"
	@echo "  make build-curl     Build a specific tool for host architecture"
	@echo "  make build-all      Build all tools for all architectures (amd64, arm64)"
	@echo "  make test           Run tests for all tools"
	@echo "  make test-curl      Run tests for a specific tool"
	@echo "  make lint           Lint Dockerfiles with hadolint"
	@echo "  make clean          Remove build artifacts"
	@echo "  make list           List available tools"
	@echo "  make help           Show this help message"
