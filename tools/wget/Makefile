# Build settings and tests for wget. The build rules are in ../common.mk.

include versions.mk

TOOL := wget
DEPS_LIBS := libssl.a
BUILD_ARGS := \
	--build-arg WGET_VERSION=$(WGET_VERSION) \
	--build-arg WGET_SOURCE_URL=$(WGET_SOURCE_URL) \
	--build-arg WGET_SOURCE_SHA256=$(WGET_SOURCE_SHA256)

include ../common.mk

test: build
	@echo "==> Testing wget binary for $(ARCH)"
	@# Check if binary exists and is executable
	@test -x $(TOOL_OUT_DIR)/$(ARCH)/wget || \
		(echo "ERROR: wget binary not found or not executable" && exit 1)
	@echo "✓ wget binary exists"
	@# Check static linking
	@$(CURDIR)/../../scripts/assert-static-elf.sh $(TOOL_OUT_DIR)/$(ARCH)/wget
	@# Run wget --version in a container
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/wget:/wget:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST) /wget --version 2>&1) && \
		echo "$$OUTPUT" | grep -qi "wget" || \
		(echo "ERROR: wget --version failed" && exit 1)
	@echo "✓ wget --version works"
	@# Run wget --help in a container
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/wget:/wget:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST) /wget --help 2>&1) && \
		echo "$$OUTPUT" | grep -qi "usage" || \
		(echo "ERROR: wget --help failed" && exit 1)
	@echo "✓ wget --help works"
	@# Run an HTTPS request against a network-isolated loopback server
	@$(DOCKER) run --rm --network none --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/wget:/wget:ro \
		-v $(DEPS_PREFIX)/bin/openssl:/openssl:ro \
		-v $(CURDIR)/../../scripts/test-local-https.sh:/test-local-https.sh:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST) \
		/bin/sh /test-local-https.sh wget /wget /openssl || \
		(echo "ERROR: wget HTTPS request failed" && exit 1)
	@echo "✓ wget HTTPS request works"
	@echo "==> All wget tests passed"
