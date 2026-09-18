# Build settings and tests for mtr. The build rules are in ../common.mk.

include versions.mk

TOOL := mtr
DEPS_LIBS := libncursesw.a
INPUTS := asn-clip-len.patch
BUILD_ARGS := \
	--build-arg MTR_VERSION=$(MTR_VERSION) \
	--build-arg MTR_SOURCE_URL=$(MTR_SOURCE_URL) \
	--build-arg MTR_SOURCE_SHA256=$(MTR_SOURCE_SHA256)

include ../common.mk

test: build
	@echo "==> Testing mtr binary for $(ARCH)"
	@test -x $(TOOL_OUT_DIR)/$(ARCH)/mtr || \
		(echo "ERROR: mtr binary not found or not executable" && exit 1)
	@echo "✓ mtr binary exists"
	@$(CURDIR)/../../scripts/assert-static-elf.sh $(TOOL_OUT_DIR)/$(ARCH)/mtr
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/mtr:/mtr:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST) /mtr --version 2>&1) && \
		echo "$$OUTPUT" | grep -q "mtr" || \
		(echo "ERROR: mtr --version failed" && exit 1)
	@echo "✓ mtr --version works"
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/mtr:/mtr:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST) /mtr --help 2>&1) && \
		echo "$$OUTPUT" | grep -qi "usage\|options\|hostname" || \
		(echo "ERROR: mtr --help failed" && exit 1)
	@echo "✓ mtr --help works"
	@echo "==> Testing mtr-packet binary for $(ARCH)"
	@test -x $(TOOL_OUT_DIR)/$(ARCH)/mtr-packet || \
		(echo "ERROR: mtr-packet binary not found or not executable" && exit 1)
	@echo "✓ mtr-packet binary exists"
	@$(CURDIR)/../../scripts/assert-static-elf.sh $(TOOL_OUT_DIR)/$(ARCH)/mtr-packet
	@# mtr-packet is a stdin protocol helper (no --version/--help flags).
	@# --version equivalent: check-support feature version
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/mtr-packet:/mtr-packet:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST) \
		/bin/sh -c 'printf "1 check-support feature version\n" | /mtr-packet' 2>&1) && \
		echo "$$OUTPUT" | grep -qi "version\|feature-support\|support" || \
		(echo "ERROR: mtr-packet version check failed: $$OUTPUT" && exit 1)
	@echo "✓ mtr-packet --version works"
	@# --help equivalent: check-support for a documented command
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/mtr-packet:/mtr-packet:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST) \
		/bin/sh -c 'printf "1 check-support feature send-probe\n" | /mtr-packet' 2>&1) && \
		echo "$$OUTPUT" | grep -qi "support\|feature\|send-probe" || \
		(echo "ERROR: mtr-packet --help failed: $$OUTPUT" && exit 1)
	@echo "✓ mtr-packet --help works"
	@echo "==> All mtr tests passed"
