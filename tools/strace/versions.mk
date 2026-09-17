include ../../deps/versions.mk

STRACE_VERSION := 7.2
STRACE_SOURCE_URL := https://github.com/strace/strace/releases/download/v$(STRACE_VERSION)/strace-$(STRACE_VERSION).tar.xz
STRACE_SOURCE_SHA256 := 4bde6246926890dcee824f6e6ac42a06752f47d77e5097d86e3c0d6d4b709fe5

# Prefix libraries statically linked into this artifact (SBOM).
SBOM_LIBS :=
