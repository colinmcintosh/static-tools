# Build settings and tests for file. The build rules are in ../common.mk.

include versions.mk

TOOL := file
DEPS_LIBS := libz.a
BUILD_ARGS := \
	--build-arg FILE_VERSION=$(FILE_VERSION) \
	--build-arg FILE_SOURCE_URL=$(FILE_SOURCE_URL) \
	--build-arg FILE_SOURCE_SHA256=$(FILE_SOURCE_SHA256)

include ../common.mk

test: build
	@echo "==> Testing file binary for $(ARCH)"
	@test -x $(TOOL_OUT_DIR)/$(ARCH)/file || (echo "ERROR: file binary not found" && exit 1)
	@test -f $(TOOL_OUT_DIR)/$(ARCH)/magic.mgc || (echo "ERROR: magic.mgc not found" && exit 1)
	@$(CURDIR)/../../scripts/assert-static-elf.sh $(TOOL_OUT_DIR)/$(ARCH)/file
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/file:/file:ro \
		-v $(TOOL_OUT_DIR)/$(ARCH)/magic.mgc:/magic.mgc:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST) /file --version 2>&1) && \
		echo "$$OUTPUT" | grep -qi "file" || (echo "ERROR: file --version failed: $$OUTPUT" && exit 1)
	@echo "✓ file --version works"
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/file:/file:ro \
		-v $(TOOL_OUT_DIR)/$(ARCH)/magic.mgc:/magic.mgc:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST) /file -m /magic.mgc /file 2>&1) && \
		echo "$$OUTPUT" | grep -qi "elf\|executable" || (echo "ERROR: file identify failed: $$OUTPUT" && exit 1)
	@echo "✓ file can identify an ELF binary"
	@echo "==> All file tests passed"
