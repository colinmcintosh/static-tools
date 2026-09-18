# Build settings and tests for jq. The build rules are in ../common.mk.

include versions.mk

TOOL := jq
BUILD_ARGS := \
	--build-arg JQ_VERSION=$(JQ_VERSION) \
	--build-arg JQ_SOURCE_URL=$(JQ_SOURCE_URL) \
	--build-arg JQ_SOURCE_SHA256=$(JQ_SOURCE_SHA256)

include ../common.mk

test: build
	@echo "==> Testing jq binary for $(ARCH)"
	@test -x $(TOOL_OUT_DIR)/$(ARCH)/jq || (echo "ERROR: jq binary not found" && exit 1)
	@$(CURDIR)/../../scripts/assert-static-elf.sh $(TOOL_OUT_DIR)/$(ARCH)/jq
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/jq:/jq:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST) /jq --version 2>&1) && \
		echo "$$OUTPUT" | grep -qi "jq" || (echo "ERROR: jq --version failed: $$OUTPUT" && exit 1)
	@echo "✓ jq --version works"
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/jq:/jq:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST) \
		/bin/sh -c 'printf "{\"a\":1}" | /jq -r .a' 2>&1) && \
		echo "$$OUTPUT" | grep -qx "1" || (echo "ERROR: jq filter failed: $$OUTPUT" && exit 1)
	@echo "✓ jq filter works"
	@echo "==> All jq tests passed"
