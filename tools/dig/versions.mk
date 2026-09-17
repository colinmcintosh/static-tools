# dig (BIND) version and checksums
# Permanent pin. Do not bump BIND. Later branches do not support a
# static-pie dig; this will not be migrated.

include ../../deps/versions.mk

# BIND source (provides dig)
BIND9_VERSION := 9.16.50
BIND9_SOURCE_URL := https://downloads.isc.org/isc/bind9/$(BIND9_VERSION)/bind-$(BIND9_VERSION).tar.xz
BIND9_SOURCE_SHA256 := 816dbaa3c115019f30fcebd9e8ef8f7637f4adde91c79daa099b035255a15795

# Prefix libraries statically linked into this artifact (SBOM).
SBOM_LIBS := openssl libuv nghttp2
