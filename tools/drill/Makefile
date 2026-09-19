# Build settings and tests for drill. The build rules are in ../common.mk.

include versions.mk

TOOL := drill
DEPS_LIBS := libssl.a
BUILD_ARGS := \
	--build-arg LDNS_VERSION=$(LDNS_VERSION) \
	--build-arg LDNS_SOURCE_URL=$(LDNS_SOURCE_URL) \
	--build-arg LDNS_SOURCE_SHA256=$(LDNS_SOURCE_SHA256)

include ../common.mk
include ../../scripts/dns-test-server.mk

test: build $(DNS_TEST_SERVER)
	@echo "==> Testing drill binary for $(ARCH)"
	@# Check if binary exists and is executable
	@test -x $(TOOL_OUT_DIR)/$(ARCH)/drill || \
		(echo "ERROR: drill binary not found or not executable" && exit 1)
	@echo "✓ drill binary exists"
	@# Check static linking
	@$(CURDIR)/../../scripts/assert-static-elf.sh $(TOOL_OUT_DIR)/$(ARCH)/drill
	@# Run drill -v in a container
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/drill:/drill:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST) /drill -v 2>&1) && \
		echo "$$OUTPUT" | grep -qi "version" || \
		(echo "ERROR: drill -v failed" && exit 1)
	@echo "✓ drill -v works"
	@# Run drill -h in a container
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/drill:/drill:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST) /drill -h 2>&1) && \
		echo "$$OUTPUT" | grep -qi "Usage" || \
		(echo "ERROR: drill -h failed" && exit 1)
	@echo "✓ drill -h works"
	@# Run a DNS query against a network-isolated loopback server
	@$(DOCKER) run --rm --network none --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/drill:/drill:ro \
		-v $(DNS_TEST_SERVER):/dns-test-server:ro \
		-v $(CURDIR)/../../scripts/test-local-dns.sh:/test-local-dns.sh:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST) \
		/bin/sh /test-local-dns.sh drill /drill /dns-test-server || \
		(echo "ERROR: drill DNS query failed" && exit 1)
	@echo "✓ drill DNS query works"
	@echo "==> All drill tests passed"
