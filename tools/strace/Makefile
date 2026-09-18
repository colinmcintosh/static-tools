# Build settings and tests for strace. The build rules are in ../common.mk.

include versions.mk

TOOL := strace
BUILD_ARGS := \
	--build-arg STRACE_VERSION=$(STRACE_VERSION) \
	--build-arg STRACE_SOURCE_URL=$(STRACE_SOURCE_URL) \
	--build-arg STRACE_SOURCE_SHA256=$(STRACE_SOURCE_SHA256)

include ../common.mk

test: build
	@echo "==> Testing strace binary for $(ARCH)"
	@test -x $(TOOL_OUT_DIR)/$(ARCH)/strace || (echo "ERROR: strace binary not found" && exit 1)
	@$(CURDIR)/../../scripts/assert-static-elf.sh $(TOOL_OUT_DIR)/$(ARCH)/strace
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/strace:/strace:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST) /strace -V 2>&1) && \
		echo "$$OUTPUT" | grep -qi "strace" || (echo "ERROR: strace -V failed: $$OUTPUT" && exit 1)
	@echo "✓ strace -V works"
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/strace:/strace:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST) /strace -e trace=none /bin/true 2>&1) && \
		echo "✓ strace /bin/true works" || (echo "ERROR: strace /bin/true failed: $$OUTPUT" && exit 1)
	@echo "==> All strace tests passed"
