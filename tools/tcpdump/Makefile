# Build settings and tests for tcpdump. The build rules are in ../common.mk.

include versions.mk

TOOL := tcpdump
DEPS_LIBS := libpcap.a
BUILD_ARGS := \
	--build-arg TCPDUMP_VERSION=$(TCPDUMP_VERSION) \
	--build-arg TCPDUMP_SOURCE_URL=$(TCPDUMP_SOURCE_URL) \
	--build-arg TCPDUMP_SOURCE_SHA256=$(TCPDUMP_SOURCE_SHA256)

include ../common.mk

test: build
	@echo "==> Testing tcpdump binary for $(ARCH)"
	@test -x $(TOOL_OUT_DIR)/$(ARCH)/tcpdump || \
		(echo "ERROR: tcpdump binary not found or not executable" && exit 1)
	@echo "✓ tcpdump binary exists"
	@$(CURDIR)/../../scripts/assert-static-elf.sh $(TOOL_OUT_DIR)/$(ARCH)/tcpdump
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/tcpdump:/tcpdump:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST) /tcpdump --version 2>&1) && \
		echo "$$OUTPUT" | grep -qi "tcpdump" || \
		(echo "ERROR: tcpdump --version failed: $$OUTPUT" && exit 1)
	@echo "✓ tcpdump --version works"
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/tcpdump:/tcpdump:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST) /tcpdump --help 2>&1) && \
		echo "$$OUTPUT" | grep -qi "usage" || \
		(echo "ERROR: tcpdump --help failed: $$OUTPUT" && exit 1)
	@echo "✓ tcpdump --help works"
	@echo "==> All tcpdump tests passed"
