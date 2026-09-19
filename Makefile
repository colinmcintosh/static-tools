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

# Every tools/<name>/ directory is a tool.
TOOLS := $(sort $(notdir $(patsubst %/,%,$(wildcard tools/*/))))

# The files each tool ships (FILES_<tool>, DATA_FILES, tool_files).
include tools/files.mk

# Release artifact names: every shipped file for both architectures. The
# release checks the built set against this list (make print-artifacts).
ARTIFACTS := $(foreach arch,amd64 arm64,$(foreach tool,$(TOOLS),$(addsuffix -$(arch),$(call tool_files,$(tool)))))

# Versioning Format: YYYY.MM.MINOR
# YYYY = year, MM = zero-padded month, MINOR = release number within month.
# Recursive (=) so `date` and `git tag` run only for version/tag-release.
YEAR = $(shell date +%Y)
MONTH = $(shell date +%m)
# Auto-increment MINOR based on last tag for this year.month
LAST_MINOR = $(shell git tag -l "v$(YEAR).$(MONTH).*" 2>/dev/null | sed 's/v[0-9]*\.[0-9]*\.\([0-9]*\).*/\1/' | sort -n | tail -1)
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

# Pinned linters. Version and SHA256 live only here; `make lint` downloads
# each archive/binary, verifies the checksum, then runs the tool. CI calls
# this target instead of re-pinning the same values.
#
# hadolint v2.12.0 — SHA256 from the GitHub release checksum files
# shellcheck v0.11.0 — SHA256 of the official linux tar.xz archives
# actionlint v1.7.12 — SHA256 from actionlint_1.7.12_checksums.txt
# actionlint covers workflow YAML and shellchecks inline `run:` blocks,
# which is where most of the shell in this repo lives.
HADOLINT_VERSION := 2.12.0
HADOLINT_SHA256_amd64 := 56de6d5e5ec427e17b74fa48d51271c7fc0d61244bf5c90e828aab8362d55010
HADOLINT_SHA256_arm64 := 5798551bf19f33951881f15eb238f90aef023f11e7ec7e9f4c37961cb87c5df6
SHELLCHECK_VERSION := 0.11.0
SHELLCHECK_SHA256_amd64 := 8c3be12b05d5c177a04c29e3c78ce89ac86f1595681cab149b65b97c4e227198
SHELLCHECK_SHA256_arm64 := 12b331c1d2db6b9eb13cfca64306b1b157a86eb69db83023e261eaa7e7c14588
ACTIONLINT_VERSION := 1.7.12
ACTIONLINT_SHA256_amd64 := 8aca8db96f1b94770f1b0d72b6dddcb1ebb8123cb3712530b08cc387b349a3d8
ACTIONLINT_SHA256_arm64 := 325e971b6ba9bfa504672e29be93c24981eeb1c07576d730e9f7c8805afff0c6

# Lint Dockerfiles, scripts, and workflows
.PHONY: lint
lint:
	@echo "==> Linting Dockerfiles, scripts, and workflows"
	@HADOLINT_SHA256="$(HADOLINT_SHA256_$(HOST_ARCH))"; \
	SHELLCHECK_SHA256="$(SHELLCHECK_SHA256_$(HOST_ARCH))"; \
	ACTIONLINT_SHA256="$(ACTIONLINT_SHA256_$(HOST_ARCH))"; \
	if [ "$(HOST_ARCH)" = "amd64" ]; then \
		HADOLINT_ASSET="hadolint-Linux-x86_64"; \
		SHELLCHECK_ASSET="shellcheck-v$(SHELLCHECK_VERSION).linux.x86_64.tar.xz"; \
		ACTIONLINT_ASSET="actionlint_$(ACTIONLINT_VERSION)_linux_amd64.tar.gz"; \
	else \
		HADOLINT_ASSET="hadolint-Linux-arm64"; \
		SHELLCHECK_ASSET="shellcheck-v$(SHELLCHECK_VERSION).linux.aarch64.tar.xz"; \
		ACTIONLINT_ASSET="actionlint_$(ACTIONLINT_VERSION)_linux_arm64.tar.gz"; \
	fi; \
	HADOLINT=$$(command -v hadolint 2>/dev/null || echo ""); \
	if [ -n "$$HADOLINT" ] && [ -x "$$HADOLINT" ] && echo "$$HADOLINT_SHA256  $$HADOLINT" | sha256sum -c - >/dev/null 2>&1; then \
		true; \
	elif echo "$$HADOLINT_SHA256  /tmp/hadolint" | sha256sum -c - >/dev/null 2>&1; then \
		HADOLINT=/tmp/hadolint; \
	else \
		echo "Installing hadolint v$(HADOLINT_VERSION)..."; \
		wget -qO /tmp/hadolint "https://github.com/hadolint/hadolint/releases/download/v$(HADOLINT_VERSION)/$$HADOLINT_ASSET"; \
		echo "$$HADOLINT_SHA256  /tmp/hadolint" | sha256sum -c -; \
		chmod +x /tmp/hadolint; \
		HADOLINT=/tmp/hadolint; \
	fi; \
	if echo "$$SHELLCHECK_SHA256  /tmp/$$SHELLCHECK_ASSET" | sha256sum -c - >/dev/null 2>&1; then \
		true; \
	else \
		echo "Installing shellcheck v$(SHELLCHECK_VERSION)..."; \
		wget -qO "/tmp/$$SHELLCHECK_ASSET" "https://github.com/koalaman/shellcheck/releases/download/v$(SHELLCHECK_VERSION)/$$SHELLCHECK_ASSET"; \
		echo "$$SHELLCHECK_SHA256  /tmp/$$SHELLCHECK_ASSET" | sha256sum -c -; \
	fi; \
	tar --no-same-owner -xJf "/tmp/$$SHELLCHECK_ASSET" -C /tmp; \
	SHELLCHECK="/tmp/shellcheck-v$(SHELLCHECK_VERSION)/shellcheck"; \
	chmod +x "$$SHELLCHECK"; \
	if echo "$$ACTIONLINT_SHA256  /tmp/$$ACTIONLINT_ASSET" | sha256sum -c - >/dev/null 2>&1; then \
		true; \
	else \
		echo "Installing actionlint v$(ACTIONLINT_VERSION)..."; \
		wget -qO "/tmp/$$ACTIONLINT_ASSET" "https://github.com/rhysd/actionlint/releases/download/v$(ACTIONLINT_VERSION)/$$ACTIONLINT_ASSET"; \
		echo "$$ACTIONLINT_SHA256  /tmp/$$ACTIONLINT_ASSET" | sha256sum -c -; \
	fi; \
	tar --no-same-owner -xzf "/tmp/$$ACTIONLINT_ASSET" -C /tmp actionlint; \
	ACTIONLINT=/tmp/actionlint; \
	chmod +x "$$ACTIONLINT"; \
	echo "==> Linting Dockerfiles"; \
	$$HADOLINT --config .hadolint.yaml builder/Dockerfile || exit 1; \
	$$HADOLINT --config .hadolint.yaml deps/Dockerfile || exit 1; \
	$$HADOLINT --config .hadolint.yaml scripts/Dockerfile.dns-test-server || exit 1; \
	for tool in $(TOOLS); do \
		$$HADOLINT --config .hadolint.yaml tools/$$tool/Dockerfile || exit 1; \
	done; \
	echo "==> Linting scripts"; \
	$$SHELLCHECK scripts/*.sh || exit 1; \
	echo "==> Linting workflows"; \
	$$ACTIONLINT -shellcheck "$$SHELLCHECK" || exit 1; \
	echo "==> Checking the BuildKit pin"; \
	scripts/assert-buildkit-pinned.sh || exit 1; \
	echo "✓ Lint passed"

# Clean build artifacts
.PHONY: clean
clean:
	rm -rf $(OUT_DIR)
	$(MAKE) -C deps clean OUT_DIR=$(OUT_DIR);
	$(foreach tool,$(TOOLS),$(MAKE) -C tools/$(tool) clean;)

# Pin-file SPDX SBOMs for every release artifact (no build required)
.PHONY: sbom
sbom:
	@echo "==> Generating SBOMs"
	scripts/generate-sbom.sh --out-dir $(OUT_DIR)/sboms $(ARTIFACTS)

.PHONY: print-artifacts
print-artifacts:
	@echo $(ARTIFACTS)

# One "TOOL FILE" line per shipped file, and the files that are not ELF
# binaries. scripts/ read tools/files.mk through these.
.PHONY: print-tool-files print-data-files
print-tool-files:
	@$(foreach tool,$(TOOLS),$(foreach file,$(call tool_files,$(tool)),echo "$(tool) $(file)";))

print-data-files:
	@echo $(DATA_FILES)

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
	@echo "  make lint           Lint Dockerfiles, scripts, and workflows"
	@echo "  make sbom           Generate SPDX SBOMs from versions.mk pins"
	@echo "  make clean          Remove build artifacts"
	@echo "  make list           List available tools"
	@echo "  make help           Show this help message"
