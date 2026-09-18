# Build settings and tests for whois. The build rules are in ../common.mk.

include versions.mk

TOOL := whois
BUILD_ARGS := \
	--build-arg WHOIS_VERSION=$(WHOIS_VERSION) \
	--build-arg WHOIS_SOURCE_URL=$(WHOIS_SOURCE_URL) \
	--build-arg WHOIS_SOURCE_SHA256=$(WHOIS_SOURCE_SHA256)

include ../common.mk

test: build
	@echo "==> Testing whois binary for $(ARCH)"
	@test -x $(TOOL_OUT_DIR)/$(ARCH)/whois || (echo "ERROR: whois binary not found" && exit 1)
	@$(CURDIR)/../../scripts/assert-static-elf.sh $(TOOL_OUT_DIR)/$(ARCH)/whois
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/whois:/whois:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST) /whois --version 2>&1) && \
		echo "$$OUTPUT" | grep -q "$(WHOIS_VERSION)" || (echo "ERROR: whois --version failed: $$OUTPUT" && exit 1)
	@echo "✓ whois --version works"
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/whois:/whois:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST) /whois --help 2>&1) && \
		echo "$$OUTPUT" | grep -qi "usage" || (echo "ERROR: whois --help failed: $$OUTPUT" && exit 1)
	@echo "✓ whois --help works"
	@echo "==> All whois tests passed"
