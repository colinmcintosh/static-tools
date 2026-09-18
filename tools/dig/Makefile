# Build settings and tests for dig. The build rules are in ../common.mk.

include versions.mk

TOOL := dig
DEPS_LIBS := libuv.a
BUILD_ARGS := \
	--build-arg BIND9_VERSION=$(BIND9_VERSION) \
	--build-arg BIND9_SOURCE_URL=$(BIND9_SOURCE_URL) \
	--build-arg BIND9_SOURCE_SHA256=$(BIND9_SOURCE_SHA256)

include ../common.mk
include ../../scripts/dns-test-server.mk

test: build $(DNS_TEST_SERVER)
	@echo "==> Testing dig binary for $(ARCH)"
	@# Check if binary exists and is executable
	@test -x $(TOOL_OUT_DIR)/$(ARCH)/dig || \
		(echo "ERROR: dig binary not found or not executable" && exit 1)
	@echo "✓ dig binary exists"
	@# Check static linking
	@$(CURDIR)/../../scripts/assert-static-elf.sh $(TOOL_OUT_DIR)/$(ARCH)/dig
	@# Run dig -v in a container
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/dig:/dig:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST) /dig -v 2>&1) && \
		echo "$$OUTPUT" | grep -qi "dig" || \
		(echo "ERROR: dig -v failed: $$OUTPUT" && exit 1)
	@echo "✓ dig -v works"
	@# Run dig -h in a container
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/dig:/dig:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST) /dig -h 2>&1) && \
		echo "$$OUTPUT" | grep -qi "usage" || \
		(echo "ERROR: dig -h failed" && exit 1)
	@echo "✓ dig -h works"
	@# Run a DNS query against a network-isolated loopback server
	@$(DOCKER) run --rm --network none --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/dig:/dig:ro \
		-v $(DNS_TEST_SERVER):/dns-test-server:ro \
		-v $(CURDIR)/../../scripts/test-local-dns.sh:/test-local-dns.sh:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST) \
		/bin/sh /test-local-dns.sh dig /dig /dns-test-server || \
		(echo "ERROR: dig DNS query failed" && exit 1)
	@echo "✓ dig DNS query works"
	@echo "==> All dig tests passed"
