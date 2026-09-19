# Build settings and tests for openssl. The build rules are in ../common.mk.

include versions.mk

TOOL := openssl
DEPS_LIBS := libssl.a

include ../common.mk

test: build
	@echo "==> Testing openssl binary for $(ARCH)"
	@test -x $(TOOL_OUT_DIR)/$(ARCH)/openssl || \
		(echo "ERROR: openssl binary not found or not executable" && exit 1)
	@echo "✓ openssl binary exists"
	@$(CURDIR)/../../scripts/assert-static-elf.sh $(TOOL_OUT_DIR)/$(ARCH)/openssl
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/openssl:/openssl:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST) /openssl version 2>&1) && \
		echo "$$OUTPUT" | grep -q "$(OPENSSL_VERSION)" || \
		(echo "ERROR: openssl version failed: $$OUTPUT" && exit 1)
	@echo "✓ openssl version works"
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/openssl:/openssl:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST) \
		/bin/sh -c 'printf test | /openssl dgst -sha256' 2>&1) && \
		echo "$$OUTPUT" | grep -qi "9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08" || \
		(echo "ERROR: openssl dgst failed: $$OUTPUT" && exit 1)
	@echo "✓ openssl dgst -sha256 works"
	@echo "==> All openssl tests passed"
