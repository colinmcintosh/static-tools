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
TOOLS := mtr drill

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

# Lint Dockerfiles and scripts
.PHONY: lint
lint:
	@echo "==> Linting Dockerfiles"
	@HADOLINT=$$(command -v hadolint 2>/dev/null || echo ""); \
	if [ -z "$$HADOLINT" ] || [ ! -x "$$HADOLINT" ]; then \
		echo "Installing hadolint..."; \
		if [ "$(HOST_ARCH)" = "amd64" ]; then \
			wget -qO /tmp/hadolint https://github.com/hadolint/hadolint/releases/download/v2.12.0/hadolint-Linux-x86_64; \
		else \
			wget -qO /tmp/hadolint https://github.com/hadolint/hadolint/releases/download/v2.12.0/hadolint-Linux-arm64; \
		fi; \
		chmod +x /tmp/hadolint; \
		HADOLINT=/tmp/hadolint; \
	fi; \
	for tool in $(TOOLS); do \
		$$HADOLINT --config .hadolint.yaml tools/$$tool/Dockerfile || exit 1; \
	done
	@echo "✓ Lint passed"

# gittuf source provenance
.PHONY: gittuf-install
gittuf-install:
	@echo "==> Installing gittuf"
	./scripts/install-gittuf.sh

.PHONY: gittuf-verify
gittuf-verify:
	@echo "==> Verifying source provenance"
	@if git show-ref --quiet refs/gittuf/policy 2>/dev/null; then \
		gittuf verify-ref --verbose main; \
	else \
		echo "gittuf not initialized - run 'gittuf setup' first"; \
	fi

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
	@echo "  make lint           Lint Dockerfiles with hadolint"
	@echo "  make gittuf-install Install gittuf locally"
	@echo "  make gittuf-verify  Verify source provenance with gittuf"
	@echo "  make clean          Remove build artifacts"
	@echo "  make list           List available tools"
	@echo "  make help           Show this help message"
