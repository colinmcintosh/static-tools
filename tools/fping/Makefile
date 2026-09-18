# Build settings and tests for fping. The build rules are in ../common.mk.

include versions.mk

TOOL := fping
BUILD_ARGS := \
	--build-arg FPING_VERSION=$(FPING_VERSION) \
	--build-arg FPING_SOURCE_URL=$(FPING_SOURCE_URL) \
	--build-arg FPING_SOURCE_SHA256=$(FPING_SOURCE_SHA256)

include ../common.mk

test: build
	@echo "==> Testing fping binary for $(ARCH)"
	@test -x $(TOOL_OUT_DIR)/$(ARCH)/fping || (echo "ERROR: fping binary not found" && exit 1)
	@$(CURDIR)/../../scripts/assert-static-elf.sh $(TOOL_OUT_DIR)/$(ARCH)/fping
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/fping:/fping:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST) /fping -v 2>&1) && \
		echo "$$OUTPUT" | grep -qi "fping" || (echo "ERROR: fping -v failed: $$OUTPUT" && exit 1)
	@echo "✓ fping -v works"
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/fping:/fping:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST) /fping -h 2>&1) && \
		echo "$$OUTPUT" | grep -qi "usage\|fping" || (echo "ERROR: fping -h failed: $$OUTPUT" && exit 1)
	@echo "✓ fping -h works"
	@echo "==> All fping tests passed"
