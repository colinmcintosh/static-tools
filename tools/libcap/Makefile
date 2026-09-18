# Build settings and tests for libcap. The build rules are in ../common.mk.

include versions.mk

TOOL := libcap
DEPS_LIBS := libcap.a
BUILD_ARGS := \
	--build-arg LIBCAP_VERSION=$(LIBCAP_VERSION) \
	--build-arg LIBCAP_URL=$(LIBCAP_URL) \
	--build-arg LIBCAP_SHA256=$(LIBCAP_SHA256)

include ../common.mk

test: build
	@echo "==> Testing getcap binary for $(ARCH)"
	@test -x $(TOOL_OUT_DIR)/$(ARCH)/getcap || \
		(echo "ERROR: getcap binary not found or not executable" && exit 1)
	@echo "✓ getcap binary exists"
	@$(CURDIR)/../../scripts/assert-static-elf.sh $(TOOL_OUT_DIR)/$(ARCH)/getcap
	@echo "==> Testing setcap binary for $(ARCH)"
	@test -x $(TOOL_OUT_DIR)/$(ARCH)/setcap || \
		(echo "ERROR: setcap binary not found or not executable" && exit 1)
	@echo "✓ setcap binary exists"
	@$(CURDIR)/../../scripts/assert-static-elf.sh $(TOOL_OUT_DIR)/$(ARCH)/setcap
	@echo "==> Testing getcap -h works (zero-library alpine container)"
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/getcap:/getcap:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST) /getcap -h 2>&1) && \
		echo "$$OUTPUT" | grep -qi "usage" || \
		(echo "ERROR: getcap -h failed: $$OUTPUT" && exit 1)
	@echo "✓ getcap -h works"
	@echo "==> Testing setcap -h works (zero-library alpine container)"
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/setcap:/setcap:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST) /setcap -h 2>&1) && \
		echo "$$OUTPUT" | grep -qi "usage" || \
		(echo "ERROR: setcap -h failed: $$OUTPUT" && exit 1)
	@echo "✓ setcap -h works"
	@echo "==> Testing setcap/getcap capability round-trip (zero-library alpine container)"
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/getcap:/getcap:ro \
		-v $(TOOL_OUT_DIR)/$(ARCH)/setcap:/setcap:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST) \
		/bin/sh -c 'touch /tmp/capfile && /setcap cap_net_raw+ep /tmp/capfile && /getcap /tmp/capfile' 2>&1) && \
		echo "$$OUTPUT" | grep -qi "cap_net_raw" || \
		(echo "ERROR: setcap/getcap round-trip failed: $$OUTPUT" && exit 1)
	@echo "✓ setcap/getcap round-trip works (setcap wrote a capability, getcap read it back)"
	@echo "==> All libcap tests passed"
