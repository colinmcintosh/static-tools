# Shared build rules for tools/<name>/Makefile.
#
# A tool Makefile includes its versions.mk, sets the variables below, includes
# this file, and then defines its own `test` target:
#
#   TOOL        its tools/ directory name
#   BUILD_ARGS  --build-arg flags for its pins (BUILDER_IMAGE and
#               BUILDER_DIGEST are added here)
#   DEPS_LIBS   shared-prefix libraries it links, such as libssl.a. When set,
#               the prefix is built first and passed as the `deps` build context.
#   INPUTS      other files its Dockerfile copies in (patches, scripts)
#
# FILES, the names the build writes to $(TOOL_OUT_DIR)/$(ARCH), comes from
# tools/files.mk.

SHELL := /bin/bash
.SHELLFLAGS := -euo pipefail -c

include $(dir $(lastword $(MAKEFILE_LIST)))files.mk

ARCH ?= amd64
ARCHS := amd64 arm64
DOCKER ?= docker
BUILDX ?= $(DOCKER) buildx
OUT_DIR ?= $(CURDIR)/../../dist
TOOL_OUT_DIR := $(OUT_DIR)/$(TOOL)
DEPS_PREFIX := $(OUT_DIR)/deps/$(ARCH)
PLATFORM_amd64 := linux/amd64
PLATFORM_arm64 := linux/arm64

FILES := $(call tool_files,$(TOOL))
OUTPUTS := $(addprefix $(TOOL_OUT_DIR)/$(ARCH)/,$(FILES))
DEPS_TARGETS := $(addprefix $(DEPS_PREFIX)/lib/,$(DEPS_LIBS))

.PHONY: build build-all clean test

build: $(OUTPUTS)

$(OUTPUTS) &: Dockerfile versions.mk $(INPUTS) $(DEPS_TARGETS)
	@mkdir -p $(TOOL_OUT_DIR)/$(ARCH)
	$(BUILDX) build \
		--platform $(PLATFORM_$(ARCH)) \
		$(if $(DEPS_LIBS),--build-context deps=$(DEPS_PREFIX)) \
		--build-arg BUILDER_IMAGE=$(BUILDER_IMAGE) \
		--build-arg BUILDER_DIGEST=$(BUILDER_DIGEST) \
		$(BUILD_ARGS) \
		--output type=local,dest=$(TOOL_OUT_DIR)/$(ARCH) \
		--target export \
		.
	@echo "Built $(TOOL) for $(ARCH):"
	@ls -la $(TOOL_OUT_DIR)/$(ARCH)/

ifneq ($(DEPS_LIBS),)
$(DEPS_TARGETS) &:
	$(MAKE) -C $(CURDIR)/../../deps build ARCH=$(ARCH) OUT_DIR=$(OUT_DIR)
endif

build-all:
	$(foreach arch,$(ARCHS),$(MAKE) build ARCH=$(arch);)

clean:
	rm -rf $(TOOL_OUT_DIR)
