# whois version and checksums
# All versions and checksums should be pinned for reproducibility

include ../../deps/versions.mk

# whois (Marco d'Itri's rfc1036/whois client). Upstream publishes only tags,
# no GitHub Releases, so this is the tag source tarball.
# Built without IDN (libidn2) support: the builder image has no pkg-config
# and this tool does not link the shared deps prefix, so upstream's
# pkg-config-based autodetection in its Makefile silently no-ops to "off".
WHOIS_VERSION := 5.6.6
WHOIS_SOURCE_URL := https://github.com/rfc1036/whois/archive/refs/tags/v$(WHOIS_VERSION).tar.gz
WHOIS_SOURCE_SHA256 := 43d3b3cc64c75e8bd10aee6feff3906e9488ed335076d206e70f3b25bf644969

# Prefix libraries statically linked into this artifact (SBOM).
SBOM_LIBS :=
