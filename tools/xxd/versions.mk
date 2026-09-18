include ../../deps/versions.mk

XXD_VERSION := 1.3.16
# Uploaded GitHub release asset, not the forge-generated tag archive.
XXD_SOURCE_URL := https://github.com/xyproto/tinyxxd/releases/download/v$(XXD_VERSION)/tinyxxd-$(XXD_VERSION).tar.gz
XXD_SOURCE_SHA256 := be313c1124fcaf56aebcac76503cd63821cc79aa036fe266c16bf9486be0d548

# Prefix libraries statically linked into this artifact (SBOM).
SBOM_LIBS :=
