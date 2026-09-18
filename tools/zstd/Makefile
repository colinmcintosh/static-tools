# Build settings and tests for zstd. The build rules are in ../common.mk.

include versions.mk

TOOL := zstd
BUILD_ARGS := \
	--build-arg ZSTD_VERSION=$(ZSTD_VERSION) \
	--build-arg ZSTD_URL=$(ZSTD_URL) \
	--build-arg ZSTD_SHA256=$(ZSTD_SHA256)

include ../common.mk

test: build
	@echo "==> Testing zstd binary for $(ARCH)"
	@# Check if binary exists and is executable
	@test -x $(TOOL_OUT_DIR)/$(ARCH)/zstd || \
		(echo "ERROR: zstd binary not found or not executable" && exit 1)
	@echo "✓ zstd binary exists"
	@# Check static linking
	@$(CURDIR)/../../scripts/assert-static-elf.sh $(TOOL_OUT_DIR)/$(ARCH)/zstd
	@# Run zstd --version in a container (zero libraries present, proving
	@# true static linking)
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/zstd:/zstd:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST) /zstd --version 2>&1) && \
		echo "$$OUTPUT" | grep -qi "zstandard" || \
		(echo "ERROR: zstd --version failed: $$OUTPUT" && exit 1)
	@echo "✓ zstd --version works"
	@# Round-trip a small test string through compress and decompress
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/zstd:/zstd:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST) /bin/sh -c '\
			set -eu; \
			msg="the quick brown fox jumps over the lazy dog"; \
			out=$$(printf "%s" "$$msg" | /zstd -c | /zstd -dc); \
			if [ "$$out" = "$$msg" ]; then echo ROUNDTRIP_OK; else echo ROUNDTRIP_MISMATCH; fi \
		' 2>&1) && \
		echo "$$OUTPUT" | grep -q "ROUNDTRIP_OK" || \
		(echo "ERROR: zstd compress/decompress round-trip failed: $$OUTPUT" && exit 1)
	@echo "✓ zstd compress/decompress round-trip works"
	@echo "==> All zstd tests passed"
