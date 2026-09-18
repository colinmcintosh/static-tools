# Build settings and tests for lsof. The build rules are in ../common.mk.

include versions.mk

TOOL := lsof
BUILD_ARGS := \
	--build-arg LSOF_VERSION=$(LSOF_VERSION) \
	--build-arg LSOF_SOURCE_URL=$(LSOF_SOURCE_URL) \
	--build-arg LSOF_SOURCE_SHA256=$(LSOF_SOURCE_SHA256)

include ../common.mk

test: build
	@echo "==> Testing lsof binary for $(ARCH)"
	@test -x $(TOOL_OUT_DIR)/$(ARCH)/lsof || (echo "ERROR: lsof binary not found" && exit 1)
	@echo "✓ lsof binary exists"
	@$(CURDIR)/../../scripts/assert-static-elf.sh $(TOOL_OUT_DIR)/$(ARCH)/lsof
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/lsof:/lsof:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST) /lsof -v 2>&1) && \
		echo "$$OUTPUT" | grep -qi "lsof version information" || \
		(echo "ERROR: lsof -v failed: $$OUTPUT" && exit 1)
	@echo "✓ lsof -v works"
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/lsof:/lsof:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST) /lsof -p 1 2>&1) && \
		echo "$$OUTPUT" | grep -q "^COMMAND" || \
		(echo "ERROR: lsof -p 1 failed: $$OUTPUT" && exit 1) && \
		echo "$$OUTPUT" | grep -qi "^lsof" || \
		(echo "ERROR: lsof -p 1 did not list its own process: $$OUTPUT" && exit 1)
	@echo "✓ lsof -p 1 works (self-inspection via /proc, zero libraries in the container)"
	@echo "==> All lsof tests passed"
