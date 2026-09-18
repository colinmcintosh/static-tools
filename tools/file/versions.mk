include ../../deps/versions.mk

FILE_VERSION := 5.48
FILE_SOURCE_URL := https://astron.com/pub/file/file-$(FILE_VERSION).tar.gz
FILE_SOURCE_SHA256 := ed14656883b23a364b4057c05595d93252da9bc473d30106519519d0da141283
FILE_SOURCE_SIG_URL := https://astron.com/pub/file/file-$(FILE_VERSION).tar.gz.asc
FILE_SOURCE_KEY := file

# Prefix libraries statically linked into this artifact (SBOM).
SBOM_LIBS := zlib
# magic.mgc is a data file from the same tarball; it does not link zlib.
SBOM_LIBS_magic.mgc :=
