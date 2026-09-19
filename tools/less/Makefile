# Build settings and tests for less. The build rules are in ../common.mk.

include versions.mk

TOOL := less
DEPS_LIBS := libncursesw.a
BUILD_ARGS := \
	--build-arg LESS_VERSION=$(LESS_VERSION) \
	--build-arg LESS_SOURCE_URL=$(LESS_SOURCE_URL) \
	--build-arg LESS_SOURCE_SHA256=$(LESS_SOURCE_SHA256)

include ../common.mk

test: build
	@echo "==> Testing less binary for $(ARCH)"
	@# Check if binary exists and is executable
	@test -x $(TOOL_OUT_DIR)/$(ARCH)/less || \
		(echo "ERROR: less binary not found or not executable" && exit 1)
	@echo "✓ less binary exists"
	@# Check static linking
	@$(CURDIR)/../../scripts/assert-static-elf.sh $(TOOL_OUT_DIR)/$(ARCH)/less
	@# Run less --version in a container (zero libraries present: proves
	@# the binary is truly self-contained, not just statically-linked-ish)
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/less:/less:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST) /less --version 2>&1) && \
		echo "$$OUTPUT" | grep -qi "less" || \
		(echo "ERROR: less --version failed: $$OUTPUT" && exit 1)
	@echo "✓ less --version works"
	@# Run less --help in a container. --help prints the built-in help
	@# screen, whose section headers (e.g. "SUMMARY OF LESS COMMANDS") are
	@# bold-by-doubling every letter (nroff-style overstrike), so match on
	@# plain-case body text instead of a header.
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/less:/less:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST) /less --help 2>&1) && \
		echo "$$OUTPUT" | grep -qi "forward\|backward" || \
		(echo "ERROR: less --help failed: $$OUTPUT" && exit 1)
	@echo "✓ less --help works"
	@# Pipe a short line of text through less non-interactively. -F
	@# (--quit-if-one-screen) makes less write the input and exit as soon
	@# as it knows the content fits on one screen, without ever opening
	@# /dev/tty for keyboard input; -X skips the termcap init/deinit
	@# sequences, which also sidesteps needing a real terminfo database.
	@# `timeout` is a backstop in case some environment still blocks on
	@# tty access despite those flags.
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/less:/less:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST) \
		/bin/sh -c 'printf "hello from less\n" | timeout 5 /less -F -X' 2>&1) && \
		echo "$$OUTPUT" | grep -q "hello from less" || \
		(echo "ERROR: less -F -X non-interactive pipe test failed: $$OUTPUT" && exit 1)
	@echo "✓ less non-interactive pipe test works"
	@echo "==> All less tests passed"
