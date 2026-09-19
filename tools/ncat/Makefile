# Build settings and tests for ncat. The build rules are in ../common.mk.

include versions.mk

TOOL := ncat
DEPS_LIBS := libssl.a
BUILD_ARGS := \
	--build-arg NMAP_VERSION=$(NMAP_VERSION) \
	--build-arg NMAP_SOURCE_URL=$(NMAP_SOURCE_URL) \
	--build-arg NMAP_SOURCE_SHA256=$(NMAP_SOURCE_SHA256)

include ../common.mk

test: build
	@echo "==> Testing ncat binary for $(ARCH)"
	@test -x $(TOOL_OUT_DIR)/$(ARCH)/ncat || \
		(echo "ERROR: ncat binary not found or not executable" && exit 1)
	@echo "✓ ncat binary exists"
	@$(CURDIR)/../../scripts/assert-static-elf.sh $(TOOL_OUT_DIR)/$(ARCH)/ncat
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/ncat:/ncat:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST) /ncat --version 2>&1) && \
		echo "$$OUTPUT" | grep -qi "ncat" || \
		(echo "ERROR: ncat --version failed: $$OUTPUT" && exit 1)
	@echo "✓ ncat --version works"
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/ncat:/ncat:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST) /ncat --help 2>&1); \
		echo "$$OUTPUT" | grep -qi "usage\|ncat" || \
		(echo "ERROR: ncat --help failed: $$OUTPUT" && exit 1); \
		echo "$$OUTPUT" | grep -q -- "--ssl" || \
		(echo "ERROR: ncat --help missing --ssl: $$OUTPUT" && exit 1)
	@echo "✓ ncat --help reports OpenSSL"
	@$(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/ncat:/ncat:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST) \
		/bin/sh -c ' /ncat -l 127.0.0.1 18765 >/tmp/ncat-out & \
			sleep 1; \
			printf ping | /ncat --send-only 127.0.0.1 18765; \
			sleep 1; \
			grep -q ping /tmp/ncat-out ' || \
		(echo "ERROR: ncat loopback test failed" && exit 1)
	@echo "✓ ncat loopback connect works"
	@echo "==> All ncat tests passed"
