# Build settings and tests for ncdu. The build rules are in ../common.mk.

include versions.mk

TOOL := ncdu
DEPS_LIBS := libncursesw.a
BUILD_ARGS := \
	--build-arg NCDU_VERSION=$(NCDU_VERSION) \
	--build-arg NCDU_SOURCE_URL=$(NCDU_SOURCE_URL) \
	--build-arg NCDU_SOURCE_SHA256=$(NCDU_SOURCE_SHA256)

include ../common.mk

test: build
	@echo "==> Testing ncdu binary for $(ARCH)"
	@test -x $(TOOL_OUT_DIR)/$(ARCH)/ncdu || (echo "ERROR: ncdu binary not found" && exit 1)
	@$(CURDIR)/../../scripts/assert-static-elf.sh $(TOOL_OUT_DIR)/$(ARCH)/ncdu
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/ncdu:/ncdu:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST) /ncdu -v 2>&1) && \
		echo "$$OUTPUT" | grep -qi "ncdu" || (echo "ERROR: ncdu -v failed: $$OUTPUT" && exit 1)
	@echo "✓ ncdu -v works"
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/ncdu:/ncdu:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST) /ncdu -h 2>&1) && \
		echo "$$OUTPUT" | grep -qi "usage\|ncdu" || (echo "ERROR: ncdu -h failed: $$OUTPUT" && exit 1)
	@echo "✓ ncdu -h works"
	@echo "==> All ncdu tests passed"
