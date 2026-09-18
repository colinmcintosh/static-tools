# Build settings and tests for iperf3. The build rules are in ../common.mk.

include versions.mk

TOOL := iperf3
DEPS_LIBS := libssl.a
BUILD_ARGS := \
	--build-arg IPERF3_VERSION=$(IPERF3_VERSION) \
	--build-arg IPERF3_SOURCE_URL=$(IPERF3_SOURCE_URL) \
	--build-arg IPERF3_SOURCE_SHA256=$(IPERF3_SOURCE_SHA256)

include ../common.mk

test: build
	@echo "==> Testing iperf3 binary for $(ARCH)"
	@# Check if binary exists and is executable
	@test -x $(TOOL_OUT_DIR)/$(ARCH)/iperf3 || \
		(echo "ERROR: iperf3 binary not found or not executable" && exit 1)
	@echo "✓ iperf3 binary exists"
	@# Check static linking
	@$(CURDIR)/../../scripts/assert-static-elf.sh $(TOOL_OUT_DIR)/$(ARCH)/iperf3
	@# Run iperf3 --version in a container
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/iperf3:/iperf3:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST) /iperf3 --version 2>&1) && \
		echo "$$OUTPUT" | grep -qi "iperf" || \
		(echo "ERROR: iperf3 --version failed" && exit 1)
	@echo "✓ iperf3 --version works"
	@# Run iperf3 --help in a container
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/iperf3:/iperf3:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST) /iperf3 --help 2>&1) && \
		echo "$$OUTPUT" | grep -qi "usage" || \
		(echo "ERROR: iperf3 --help failed" && exit 1)
	@echo "✓ iperf3 --help works"
	@echo "==> All iperf3 tests passed"
