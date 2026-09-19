# Build settings and tests for curl. The build rules are in ../common.mk.

include versions.mk

TOOL := curl
DEPS_LIBS := libssl.a
BUILD_ARGS := \
	--build-arg CURL_VERSION=$(CURL_VERSION) \
	--build-arg CURL_SOURCE_URL=$(CURL_SOURCE_URL) \
	--build-arg CURL_SOURCE_SHA256=$(CURL_SOURCE_SHA256)

include ../common.mk

test: build
	@echo "==> Testing curl binary for $(ARCH)"
	@# Check if binary exists and is executable
	@test -x $(TOOL_OUT_DIR)/$(ARCH)/curl || \
		(echo "ERROR: curl binary not found or not executable" && exit 1)
	@echo "✓ curl binary exists"
	@# Check static linking
	@$(CURDIR)/../../scripts/assert-static-elf.sh $(TOOL_OUT_DIR)/$(ARCH)/curl
	@# Run curl --version in a container
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/curl:/curl:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST) /curl --version 2>&1) && \
		echo "$$OUTPUT" | grep -qi "curl" || \
		(echo "ERROR: curl --version failed: $$OUTPUT" && exit 1)
	@echo "✓ curl --version works"
	@# Run curl --help in a container
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/curl:/curl:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST) /curl --help 2>&1) && \
		echo "$$OUTPUT" | grep -qi "usage" || \
		(echo "ERROR: curl --help failed" && exit 1)
	@echo "✓ curl --help works"
	@# Run an HTTPS request against a network-isolated loopback server
	@$(DOCKER) run --rm --network none --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/curl:/curl:ro \
		-v $(DEPS_PREFIX)/bin/openssl:/openssl:ro \
		-v $(CURDIR)/../../scripts/test-local-https.sh:/test-local-https.sh:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST) \
		/bin/sh /test-local-https.sh curl /curl /openssl || \
		(echo "ERROR: curl HTTPS request failed" && exit 1)
	@echo "✓ curl HTTPS request works"
	@echo "==> All curl tests passed"
