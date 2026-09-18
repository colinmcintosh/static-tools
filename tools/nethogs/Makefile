# Build settings and tests for nethogs. The build rules are in ../common.mk.

include versions.mk

TOOL := nethogs
DEPS_LIBS := libpcap.a
BUILD_ARGS := \
	--build-arg NETHOGS_VERSION=$(NETHOGS_VERSION) \
	--build-arg NETHOGS_SOURCE_URL=$(NETHOGS_SOURCE_URL) \
	--build-arg NETHOGS_SOURCE_SHA256=$(NETHOGS_SOURCE_SHA256)

include ../common.mk

test: build
	@echo "==> Testing nethogs binary for $(ARCH)"
	@# Check if binary exists and is executable
	@test -x $(TOOL_OUT_DIR)/$(ARCH)/nethogs || \
		(echo "ERROR: nethogs binary not found or not executable" && exit 1)
	@echo "✓ nethogs binary exists"
	@# Check static linking
	@$(CURDIR)/../../scripts/assert-static-elf.sh $(TOOL_OUT_DIR)/$(ARCH)/nethogs
	@# Run nethogs -V (version) in a throwaway container with zero libraries,
	@# which proves the binary is genuinely statically linked.
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/nethogs:/nethogs:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST) /nethogs -V 2>&1) && \
		echo "$$OUTPUT" | grep -q "$(NETHOGS_VERSION)" || \
		(echo "ERROR: nethogs -V failed: $$OUTPUT" && exit 1)
	@echo "✓ nethogs -V works"
	@# Run nethogs -h (help) in a container
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/nethogs:/nethogs:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST) /nethogs -h 2>&1) && \
		echo "$$OUTPUT" | grep -qi "usage" || \
		(echo "ERROR: nethogs -h failed: $$OUTPUT" && exit 1)
	@echo "✓ nethogs -h works"
	@echo "==> All nethogs tests passed"
