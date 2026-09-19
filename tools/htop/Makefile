# Build settings and tests for htop. The build rules are in ../common.mk.

include versions.mk

TOOL := htop
DEPS_LIBS := libncursesw.a
BUILD_ARGS := \
	--build-arg HTOP_VERSION=$(HTOP_VERSION) \
	--build-arg HTOP_SOURCE_URL=$(HTOP_SOURCE_URL) \
	--build-arg HTOP_SOURCE_SHA256=$(HTOP_SOURCE_SHA256)

include ../common.mk

test: build
	@echo "==> Testing htop binary for $(ARCH)"
	@test -x $(TOOL_OUT_DIR)/$(ARCH)/htop || (echo "ERROR: htop binary not found" && exit 1)
	@$(CURDIR)/../../scripts/assert-static-elf.sh $(TOOL_OUT_DIR)/$(ARCH)/htop
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/htop:/htop:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST) /htop --version 2>&1) && \
		echo "$$OUTPUT" | grep -qi "htop" || (echo "ERROR: htop --version failed: $$OUTPUT" && exit 1)
	@echo "✓ htop --version works"
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/htop:/htop:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST) /htop --help 2>&1) && \
		echo "$$OUTPUT" | grep -qi "usage\|htop" || (echo "ERROR: htop --help failed: $$OUTPUT" && exit 1)
	@echo "✓ htop --help works"
	@echo "==> All htop tests passed"
