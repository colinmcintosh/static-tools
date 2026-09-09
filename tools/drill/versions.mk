# drill (ldns) version and checksums
# All versions and checksums should be pinned for reproducibility

include ../../deps/versions.mk

# ldns source (provides drill, a dig-like DNS tool)
LDNS_VERSION := 1.9.2
LDNS_SOURCE_URL := https://nlnetlabs.nl/downloads/ldns/ldns-$(LDNS_VERSION).tar.gz
LDNS_SOURCE_SHA256 := b524fa21994b6e834200ceb8c27f1b84bda5982fe35706f058196c079db94d5d
