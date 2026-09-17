# sysstat build targets (mpstat, iostat, pidstat, sar)

SHELL := /bin/bash
.SHELLFLAGS := -euo pipefail -c

include versions.mk

ARCH ?= amd64
ARCHS := amd64 arm64
DOCKER ?= docker
BUILDX ?= $(DOCKER) buildx
OUT_DIR ?= $(CURDIR)/../../dist
TOOL_OUT_DIR := $(OUT_DIR)/sysstat
PLATFORM_amd64 := linux/amd64
PLATFORM_arm64 := linux/arm64
ALPINE_DIGEST_amd64 := $(ALPINE_DIGEST_AMD64)
ALPINE_DIGEST_arm64 := $(ALPINE_DIGEST_ARM64)

BINARIES := mpstat iostat pidstat sar

.PHONY: build build-all test verify-static clean info

build: $(addprefix $(TOOL_OUT_DIR)/$(ARCH)/,$(BINARIES))

$(TOOL_OUT_DIR)/$(ARCH)/mpstat $(TOOL_OUT_DIR)/$(ARCH)/iostat $(TOOL_OUT_DIR)/$(ARCH)/pidstat $(TOOL_OUT_DIR)/$(ARCH)/sar &: Dockerfile versions.mk
	@mkdir -p $(TOOL_OUT_DIR)/$(ARCH)
	$(BUILDX) build \
		--platform $(PLATFORM_$(ARCH)) \
		--build-arg BUILDER_IMAGE=$(BUILDER_IMAGE) \
		--build-arg BUILDER_DIGEST=$(BUILDER_DIGEST) \
		--build-arg SYSSTAT_VERSION=$(SYSSTAT_VERSION) \
		--build-arg SYSSTAT_SOURCE_SHA256=$(SYSSTAT_SOURCE_SHA256) \
		--output type=local,dest=$(TOOL_OUT_DIR)/$(ARCH) \
		--target export \
		.
	@echo "Built sysstat $(SYSSTAT_VERSION) for $(ARCH):"
	@ls -la $(TOOL_OUT_DIR)/$(ARCH)/

# Build for all architectures
build-all:
	$(foreach arch,$(ARCHS),$(MAKE) build ARCH=$(arch);)

# Test the binaries. Each of the 4 binaries reads /proc directly and does not
# need sadc: mpstat/iostat/pidstat sample /proc themselves, and sar's -V path
# does not touch the data collector either. (sar's live-collection mode,
# `sar <interval> <count>`, execs a separate `sadc` binary at runtime; sadc is
# out of scope for this tool, so only `sar -V` is exercised here.)
test: build
	@echo "==> Testing mpstat binary for $(ARCH)"
	@test -x $(TOOL_OUT_DIR)/$(ARCH)/mpstat || \
		(echo "ERROR: mpstat binary not found or not executable" && exit 1)
	@echo "✓ mpstat binary exists"
	@$(CURDIR)/../../scripts/assert-static-elf.sh $(TOOL_OUT_DIR)/$(ARCH)/mpstat
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/mpstat:/mpstat:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST_$(ARCH)) /mpstat -V 2>&1) && \
		echo "$$OUTPUT" | grep -qi "sysstat" || \
		(echo "ERROR: mpstat -V failed: $$OUTPUT" && exit 1)
	@echo "✓ mpstat -V works"
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/mpstat:/mpstat:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST_$(ARCH)) /mpstat 1 1 2>&1) && \
		echo "$$OUTPUT" | grep -qi "CPU" || \
		(echo "ERROR: mpstat 1 1 failed: $$OUTPUT" && exit 1)
	@echo "✓ mpstat 1 1 works (live /proc read)"
	@echo "==> Testing iostat binary for $(ARCH)"
	@test -x $(TOOL_OUT_DIR)/$(ARCH)/iostat || \
		(echo "ERROR: iostat binary not found or not executable" && exit 1)
	@echo "✓ iostat binary exists"
	@$(CURDIR)/../../scripts/assert-static-elf.sh $(TOOL_OUT_DIR)/$(ARCH)/iostat
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/iostat:/iostat:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST_$(ARCH)) /iostat -V 2>&1) && \
		echo "$$OUTPUT" | grep -qi "sysstat" || \
		(echo "ERROR: iostat -V failed: $$OUTPUT" && exit 1)
	@echo "✓ iostat -V works"
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/iostat:/iostat:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST_$(ARCH)) /iostat 2>&1) && \
		echo "$$OUTPUT" | grep -qi "Device" || \
		(echo "ERROR: iostat failed: $$OUTPUT" && exit 1)
	@echo "✓ iostat works (live /proc read)"
	@echo "==> Testing pidstat binary for $(ARCH)"
	@test -x $(TOOL_OUT_DIR)/$(ARCH)/pidstat || \
		(echo "ERROR: pidstat binary not found or not executable" && exit 1)
	@echo "✓ pidstat binary exists"
	@$(CURDIR)/../../scripts/assert-static-elf.sh $(TOOL_OUT_DIR)/$(ARCH)/pidstat
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/pidstat:/pidstat:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST_$(ARCH)) /pidstat -V 2>&1) && \
		echo "$$OUTPUT" | grep -qi "sysstat" || \
		(echo "ERROR: pidstat -V failed: $$OUTPUT" && exit 1)
	@echo "✓ pidstat -V works"
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/pidstat:/pidstat:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST_$(ARCH)) /pidstat 1 1 2>&1) && \
		echo "$$OUTPUT" | grep -qi "Command" || \
		(echo "ERROR: pidstat 1 1 failed: $$OUTPUT" && exit 1)
	@echo "✓ pidstat 1 1 works (live /proc read)"
	@echo "==> Testing sar binary for $(ARCH)"
	@test -x $(TOOL_OUT_DIR)/$(ARCH)/sar || \
		(echo "ERROR: sar binary not found or not executable" && exit 1)
	@echo "✓ sar binary exists"
	@$(CURDIR)/../../scripts/assert-static-elf.sh $(TOOL_OUT_DIR)/$(ARCH)/sar
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/sar:/sar:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST_$(ARCH)) /sar -V 2>&1) && \
		echo "$$OUTPUT" | grep -qi "sysstat" || \
		(echo "ERROR: sar -V failed: $$OUTPUT" && exit 1)
	@echo "✓ sar -V works"
	@echo "==> All sysstat tests passed"

verify-static: build
	@$(CURDIR)/../../scripts/assert-static-elf.sh $(addprefix $(TOOL_OUT_DIR)/$(ARCH)/,$(BINARIES))

# Clean build artifacts
clean:
	rm -rf $(TOOL_OUT_DIR)

info:
	@echo "Tool: sysstat $(SYSSTAT_VERSION)"
	@echo "URL: $(SYSSTAT_SOURCE_URL)"
	@echo "SHA256: $(SYSSTAT_SOURCE_SHA256)"
	@echo "Binaries: $(BINARIES)"
