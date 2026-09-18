# Build settings and tests for xxd. The build rules are in ../common.mk.

include versions.mk

TOOL := xxd
BUILD_ARGS := \
	--build-arg XXD_VERSION=$(XXD_VERSION) \
	--build-arg XXD_SOURCE_URL=$(XXD_SOURCE_URL) \
	--build-arg XXD_SOURCE_SHA256=$(XXD_SOURCE_SHA256)

include ../common.mk

test: build
	@echo "==> Testing xxd binary for $(ARCH)"
	@test -x $(TOOL_OUT_DIR)/$(ARCH)/xxd || (echo "ERROR: xxd binary not found" && exit 1)
	@$(CURDIR)/../../scripts/assert-static-elf.sh $(TOOL_OUT_DIR)/$(ARCH)/xxd
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/xxd:/xxd:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST) \
		/bin/sh -c 'printf ABC | /xxd' 2>&1) && \
		echo "$$OUTPUT" | grep -qi "4142" || (echo "ERROR: xxd encode failed: $$OUTPUT" && exit 1)
	@echo "✓ xxd encodes hex"
	@echo "==> All xxd tests passed"
