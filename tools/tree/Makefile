# Build settings and tests for tree. The build rules are in ../common.mk.

include versions.mk

TOOL := tree
BUILD_ARGS := \
	--build-arg TREE_VERSION=$(TREE_VERSION) \
	--build-arg TREE_SOURCE_URL=$(TREE_SOURCE_URL) \
	--build-arg TREE_SOURCE_SHA256=$(TREE_SOURCE_SHA256)

include ../common.mk

test: build
	@echo "==> Testing tree binary for $(ARCH)"
	@test -x $(TOOL_OUT_DIR)/$(ARCH)/tree || (echo "ERROR: tree binary not found" && exit 1)
	@$(CURDIR)/../../scripts/assert-static-elf.sh $(TOOL_OUT_DIR)/$(ARCH)/tree
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/tree:/tree:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST) /tree --version 2>&1) && \
		echo "$$OUTPUT" | grep -qi "tree v$(TREE_VERSION)" || (echo "ERROR: tree --version failed: $$OUTPUT" && exit 1)
	@echo "✓ tree --version works"
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/tree:/tree:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST) \
		/bin/sh -c 'mkdir -p /fixture/subdir && touch /fixture/file-a.txt /fixture/subdir/file-b.txt && /tree /fixture' 2>&1) && \
		( echo "$$OUTPUT" | grep -q "file-a.txt" ) && \
		( echo "$$OUTPUT" | grep -q "subdir" ) && \
		( echo "$$OUTPUT" | grep -q "file-b.txt" ) && \
		( echo "$$OUTPUT" | grep -qi "2 directories, 2 files\|directories.*files" ) || \
		(echo "ERROR: tree directory listing failed: $$OUTPUT" && exit 1)
	@echo "✓ tree lists a real directory structure"
	@echo "==> All tree tests passed"
