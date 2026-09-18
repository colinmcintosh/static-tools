# Build settings and tests for iproute2. The build rules are in ../common.mk.

include versions.mk

TOOL := iproute2
DEPS_LIBS := libcap.a
BUILD_ARGS := \
	--build-arg IPROUTE2_VERSION=$(IPROUTE2_VERSION) \
	--build-arg IPROUTE2_SOURCE_URL=$(IPROUTE2_SOURCE_URL) \
	--build-arg IPROUTE2_SOURCE_SHA256=$(IPROUTE2_SOURCE_SHA256)

include ../common.mk

test: build
	@echo "==> Testing ip binary for $(ARCH)"
	@test -x $(TOOL_OUT_DIR)/$(ARCH)/ip || \
		(echo "ERROR: ip binary not found or not executable" && exit 1)
	@echo "✓ ip binary exists"
	@$(CURDIR)/../../scripts/assert-static-elf.sh $(TOOL_OUT_DIR)/$(ARCH)/ip
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/ip:/ip:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST) /ip -V 2>&1) && \
		echo "$$OUTPUT" | grep -qi "iproute2" || \
		(echo "ERROR: ip -V failed: $$OUTPUT" && exit 1)
	@echo "✓ ip --version works"
	@# Plain `ip help` intentionally exits non-zero (it is iproute2's
	@# usage/error path, same as invalid arguments), so it cannot be used
	@# in a strict &&-chain like the other tools' --help checks. `ip addr
	@# show` is used instead: it exercises a real netlink round trip
	@# (not just argv parsing) and always succeeds even in a minimal,
	@# unprivileged container because the loopback interface always exists.
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/ip:/ip:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST) /ip addr show 2>&1) && \
		echo "$$OUTPUT" | grep -qi "LOOPBACK" || \
		(echo "ERROR: ip addr show failed: $$OUTPUT" && exit 1)
	@echo "✓ ip addr show works"
	@echo "==> Testing ss binary for $(ARCH)"
	@test -x $(TOOL_OUT_DIR)/$(ARCH)/ss || \
		(echo "ERROR: ss binary not found or not executable" && exit 1)
	@echo "✓ ss binary exists"
	@$(CURDIR)/../../scripts/assert-static-elf.sh $(TOOL_OUT_DIR)/$(ARCH)/ss
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/ss:/ss:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST) /ss --version 2>&1) && \
		echo "$$OUTPUT" | grep -qi "iproute2" || \
		(echo "ERROR: ss --version failed: $$OUTPUT" && exit 1)
	@echo "✓ ss --version works"
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/ss:/ss:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST) /ss --help 2>&1) && \
		echo "$$OUTPUT" | grep -qi "usage" || \
		(echo "ERROR: ss --help failed" && exit 1)
	@echo "✓ ss --help works"
	@echo "==> All iproute2 tests passed"
