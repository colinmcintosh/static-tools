include ../../deps/versions.mk

FILE_VERSION := 5.46
FILE_SOURCE_URL := https://astron.com/pub/file/file-$(FILE_VERSION).tar.gz
FILE_SOURCE_SHA256 := c9cc77c7c560c543135edc555af609d5619dbef011997e988ce40a3d75d86088

# Prefix libraries statically linked into this artifact (SBOM).
SBOM_LIBS := zlib
# magic.mgc is a data file from the same tarball; it does not link zlib.
SBOM_LIBS_magic.mgc :=
