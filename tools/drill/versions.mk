# drill (ldns) version and checksums
# All versions and checksums should be pinned for reproducibility

include ../../deps/versions.mk

# ldns source (provides drill, a dig-like DNS tool)
LDNS_VERSION := 1.8.4
LDNS_SOURCE_URL := https://nlnetlabs.nl/downloads/ldns/ldns-$(LDNS_VERSION).tar.gz
LDNS_SOURCE_SHA256 := 838b907594baaff1cd767e95466a7745998ae64bc74be038dccc62e2de2e4247
