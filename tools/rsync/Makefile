# Build settings and tests for rsync. The build rules are in ../common.mk.

include versions.mk

TOOL := rsync
DEPS_LIBS := libzstd.a
BUILD_ARGS := \
	--build-arg RSYNC_VERSION=$(RSYNC_VERSION) \
	--build-arg RSYNC_SOURCE_URL=$(RSYNC_SOURCE_URL) \
	--build-arg RSYNC_SOURCE_SHA256=$(RSYNC_SOURCE_SHA256)

include ../common.mk

test: build
	@echo "==> Testing rsync binary for $(ARCH)"
	@test -x $(TOOL_OUT_DIR)/$(ARCH)/rsync || \
		(echo "ERROR: rsync binary not found or not executable" && exit 1)
	@echo "✓ rsync binary exists"
	@$(CURDIR)/../../scripts/assert-static-elf.sh $(TOOL_OUT_DIR)/$(ARCH)/rsync
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/rsync:/rsync:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST) /rsync --version 2>&1); \
		echo "$$OUTPUT" | grep -qi "rsync" || \
		(echo "ERROR: rsync --version failed: $$OUTPUT" && exit 1); \
		echo "$$OUTPUT" | grep -qi "xxhash" || \
		(echo "ERROR: rsync --version missing xxhash: $$OUTPUT" && exit 1); \
		echo "$$OUTPUT" | grep -qi "zstd" || \
		(echo "ERROR: rsync --version missing zstd: $$OUTPUT" && exit 1); \
		echo "$$OUTPUT" | grep -qi "lz4" || \
		(echo "ERROR: rsync --version missing lz4: $$OUTPUT" && exit 1); \
		echo "$$OUTPUT" | grep -qi "openssl" || \
		(echo "ERROR: rsync --version missing openssl: $$OUTPUT" && exit 1)
	@echo "✓ rsync --version reports xxhash/zstd/lz4/openssl"
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/rsync:/rsync:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST) /rsync --help 2>&1) && \
		echo "$$OUTPUT" | grep -qi "usage" || \
		(echo "ERROR: rsync --help failed: $$OUTPUT" && exit 1)
	@echo "✓ rsync --help works"
	@$(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/rsync:/rsync:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST) \
		/bin/sh -c 'printf hello > /tmp/src && mkdir /tmp/dst && /rsync -a /tmp/src /tmp/dst/ && grep -q hello /tmp/dst/src' || \
		(echo "ERROR: rsync file copy failed" && exit 1)
	@echo "✓ rsync file copy works"
	@echo "==> All rsync tests passed"
