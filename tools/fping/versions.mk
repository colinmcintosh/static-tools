include ../../deps/versions.mk

FPING_VERSION := 5.5
FPING_SOURCE_URL := https://github.com/schweikert/fping/releases/download/v$(FPING_VERSION)/fping-$(FPING_VERSION).tar.gz
FPING_SOURCE_SHA256 := 15c4e32b6c55ff105bafe03e8c91c7ca1b2eda31bf9a7127326bb87887ee18fe

# Prefix libraries statically linked into this artifact (SBOM).
SBOM_LIBS :=
