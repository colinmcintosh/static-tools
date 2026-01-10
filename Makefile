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

# Docker configuration
DOCKER ?= docker
BUILDX ?= $(DOCKER) buildx

# Output directory
OUT_DIR := $(CURDIR)/dist

# All tools
TOOLS := mtr

# Default target
.PHONY: all
all: build

# Build all tools for host architecture (local development)
.PHONY: build
build: $(addprefix build-,$(TOOLS))

# Build specific tool for host architecture
.PHONY: build-%
build-%:
	@echo "==> Building $* for $(HOST_ARCH)"
	$(MAKE) -C tools/$* build ARCH=$(HOST_ARCH) OUT_DIR=$(OUT_DIR)

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
	$(MAKE) -C tools/$* test ARCH=$(HOST_ARCH)

# Verify provenance of release artifacts
.PHONY: verify
verify:
	@echo "==> Verifying provenance"
	./scripts/verify.sh

# Clean build artifacts
.PHONY: clean
clean:
	rm -rf $(OUT_DIR)
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
	@echo "  make build          Build all tools for host architecture ($(HOST_ARCH))"
	@echo "  make build-mtr      Build specific tool for host architecture"
	@echo "  make build-all      Build all tools for all architectures (amd64, arm64)"
	@echo "  make test           Run tests for all tools"
	@echo "  make test-mtr       Run tests for specific tool"
	@echo "  make verify         Verify provenance of release artifacts"
	@echo "  make clean          Remove build artifacts"
	@echo "  make list           List available tools"
	@echo "  make help           Show this help message"
