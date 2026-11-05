# Build settings and tests for ipmitool. The build rules are in ../common.mk.

include versions.mk

TOOL := ipmitool
DEPS_LIBS := libssl.a
BUILD_ARGS := \
	--build-arg IPMITOOL_VERSION=$(IPMITOOL_VERSION) \
	--build-arg IPMITOOL_SOURCE_URL=$(IPMITOOL_SOURCE_URL) \
	--build-arg IPMITOOL_SOURCE_SHA256=$(IPMITOOL_SOURCE_SHA256)

include ../common.mk

test: build
	@echo "==> Testing ipmitool binary for $(ARCH)"
	@test -x $(TOOL_OUT_DIR)/$(ARCH)/ipmitool || (echo "ERROR: ipmitool binary not found" && exit 1)
	@$(CURDIR)/../../scripts/assert-static-elf.sh $(TOOL_OUT_DIR)/$(ARCH)/ipmitool
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/ipmitool:/ipmitool:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST) /ipmitool -V 2>&1) && \
		echo "$$OUTPUT" | grep -qi "ipmitool version $(IPMITOOL_VERSION)" || \
		(echo "ERROR: ipmitool -V failed: $$OUTPUT" && exit 1)
	@echo "✓ ipmitool -V works"
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/ipmitool:/ipmitool:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST) /ipmitool -h 2>&1) && \
		echo "$$OUTPUT" | grep -qi "lanplus" || \
		(echo "ERROR: ipmitool -h missing lanplus: $$OUTPUT" && exit 1)
	@echo "✓ ipmitool -h lists lanplus"
	@echo "==> All ipmitool tests passed"
