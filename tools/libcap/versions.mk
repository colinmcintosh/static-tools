# libcap version and checksums
#
# libcap is already fetched, verified, and built into the shared static
# prefix (see deps/versions.mk and deps/Dockerfile: LIBCAP_VERSION,
# LIBCAP_URL, LIBCAP_SHA256), because libcap.a / libpsx.a are shared
# static libraries other tools can also link against. Reuse that exact
# same pinned/verified source here instead of defining a second pin, so
# there is a single source of truth for the libcap version.

include ../../deps/versions.mk

# scripts/generate-sbom.sh parses this file's own lines and does not follow
# `include`, so it needs a literal version assignment here too. Keep this in
# sync with LIBCAP_VERSION in deps/versions.mk (the URL/SHA256 above are
# looked up there automatically once this points it at the right prefix).
LIBCAP_VERSION := 2.78

# Prefix libraries statically linked into this artifact (SBOM). Applies to
# both getcap and setcap alike.
SBOM_LIBS := libcap
