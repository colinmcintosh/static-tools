# Build settings and tests for socat. The build rules are in ../common.mk.

include versions.mk

TOOL := socat
DEPS_LIBS := libssl.a
BUILD_ARGS := \
	--build-arg SOCAT_VERSION=$(SOCAT_VERSION) \
	--build-arg SOCAT_SOURCE_URL=$(SOCAT_SOURCE_URL) \
	--build-arg SOCAT_SOURCE_SHA256=$(SOCAT_SOURCE_SHA256)

include ../common.mk

test: build
	@echo "==> Testing socat binary for $(ARCH)"
	@test -x $(TOOL_OUT_DIR)/$(ARCH)/socat || (echo "ERROR: socat binary not found" && exit 1)
	@$(CURDIR)/../../scripts/assert-static-elf.sh $(TOOL_OUT_DIR)/$(ARCH)/socat
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/socat:/socat:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST) /socat -V 2>&1) && \
		echo "$$OUTPUT" | grep -qi "socat" || (echo "ERROR: socat -V failed: $$OUTPUT" && exit 1)
	@echo "✓ socat -V works"
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/socat:/socat:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST) /socat -V 2>&1) && \
		echo "$$OUTPUT" | grep -qi "openssl" || (echo "ERROR: socat missing OpenSSL: $$OUTPUT" && exit 1)
	@echo "✓ socat is built with OpenSSL"
	@echo "==> All socat tests passed"
